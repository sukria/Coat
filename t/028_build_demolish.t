use Test::More 'no_plan';

use strict;
use warnings;

my $REG = {};

{
    package A;
    use Coat;

    has id => (is => 'rw', isa => 'Int');

    has buffer => (
        is => 'rw', 
        isa => 'ArrayRef[Str]',
        required => 1,
        default => sub { [] },
    );

    sub BUILD { 
        push @{ $_[0]->buffer }, 'BUILD A' ;
    }

    sub DEMOLISH { 
        $REG->{'A'}{ $_[0]->id } = $_[0]->buffer;
    }

    package B;
    use Coat;
    extends 'A';

    sub BUILD { 
        push @{ $_[0]->buffer }, 'BUILD B' ;
    }
    
    sub DEMOLISH { 
        $REG->{'B'}{ $_[0]->id } = $_[0]->buffer;
    }
}

my $a = A->new( id => 1 );
is_deeply( $a->buffer, ['BUILD A'], 'A::BUILD called on new' );

my $b = B->new( id => 2 );
is_deeply( $b->buffer, ['BUILD A', 'BUILD B'], 'A::BUILD and B::BUILD called' );

undef $a;
is_deeply( $REG->{'A'}{1}, ['BUILD A'], 
    'A::DEMOLISH called for $a' );

undef $b;
is_deeply( $REG->{'A'}{2}, ['BUILD A', 'BUILD B'], 
    'A::DEMOLISH called for $b' );
is_deeply( $REG->{'B'}{2}, ['BUILD A', 'BUILD B'], 
    'B::DEMOLISH called for $b' );

