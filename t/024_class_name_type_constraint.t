use Test::More 'no_plan';

use strict;
use warnings;

{ 
    package A;
    use Coat;
    use Coat::Types;

    has x => (is => 'rw', isa => 'Num' );
    has b => (is => 'rw', isa => 'B', coerce => 1);

    coerce 'B' 
        => from 'A'
        => via { B->new (x => 3) };

    has c => (is => 'rw', isa => 'C');

    package B;
    use Coat;
    has x => (is => 'rw', isa => 'Num' );

    package C;
    use Coat;
    has x => (is => 'rw', isa => 'Num' );
}

my $a = new A ( x => 1 );
my $b = new B ( x => 2 );

ok( $a->b($b), '$a->b($b)' );
is( $a->b->x, 2, "b->x == 2");

ok( $a->b($a), '$a->b($b)' );
is( $a->b->x, 3, "b->x == 3 (coerced)");

eval { $a->c( A->new ) };
ok( $@, 'Cannot set a A object in c (B constraint)' );

eval { $a->c( "Perl Moose is just amazing" ) };
ok( $@, 'Cannot set a String in c (Ref constraint)' );

eval { $a->c( {} ) };
ok( $@, 'Cannot set a HashRef in c (Object constraint)' );
