use Test::More 'no_plan';

use strict;
use warnings;

{
    package A;
    use Coat;
    has x => (is => 'rw', isa => 'Num', default => 42);

    package B;
    use Coat;
    extends 'A';
    has '+x' => (default => 23);
}

my $a = A->new;
my $b = B->new;

is ($a->x, 42, 'default value for a->x is 42' );
is ($b->x, 23, 'default value for b->x is 23' );
