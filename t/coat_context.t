use Test::More tests => 2;
use strict;
use warnings;

{
    package Foo;
    use Coat;
    var 'x';

    sub context1 { wantarray ? 'list' : 'scalar' }
    sub context2 { wantarray ? 'list' : 'scalar' }
}
{
    package Bar;
    use Coat;
    extends Foo::;

    after context2 => sub { $_[1] };
}

my $p = Bar::;

my $scalar1 = $p->context1;
my $scalar2 = $p->context2;

my ($list1) = $p->context1;
my ($list2) = $p->context2;

is($scalar1, $scalar2, 'scalar');
is($list1, $list2, 'list');

