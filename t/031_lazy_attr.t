use Test::More tests => 5;

use strict;
use warnings;

{
    package A;
    use Coat;

    has x => (isa => 'Num', is => 'rw', lazy => 1, default => 2);
    has y => (isa => 'Num', is => 'rw', default => 2);

    package B;
    use Coat;

    has x => (isa => 'Num', is => 'rw', lazy => 1);
    
    package Test;
    use Coat;

    has dir => ( is => 'rw', isa => 'Str');
    has name => ( is => 'rw', isa => 'Str');
    has path => ( is => 'ro', isa => 'Str', lazy => 1,
        default => sub { 
            return $_[0]->dir . '/' . $_[0]->name;
        }
    );
}

my $a = A->new;

ok(! $a->{x}, 'x is not set on new (lazy)' );
ok(  $a->{y}, 'y is set on new (non-lazy)' );

is( $a->x, 2, 'x is set when read' );

my $b;
eval { $b = B->new };
ok( $@, 'Cannot have a lazy attribute without a default value');

my $t = Test->new(dir => '/tmp', name => 'file');
is($t->path, '/tmp/file', 'default lazy value with dynamic values');

