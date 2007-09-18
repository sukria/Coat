use Test::More tests => 3;
use strict;
use warnings;

{
    package Foo;
    use Coat;
}
{
    package Bar;
    use Coat;

    sub virtual { die 'override me' }
}
{
    package Baz;
    use Coat;

    has 'x';
}

ok(eval { extends Foo::; 1 }, 'completely empty'."- $@");
ok(eval { extends Bar::; 1 }, 'with a method'."- $@");
ok(eval { extends Baz::; 1 }, 'with an attribute'."- $@");
