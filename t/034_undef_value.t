use strict;
use warnings;
use Test::More 'no_plan';

{
    package A;
    use Coat;
    has one => (isa => 'Int');
}

my $a = A->new(one => undef);
ok( !defined($a->one), "one is undef" );
