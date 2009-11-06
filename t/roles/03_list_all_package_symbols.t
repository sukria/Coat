use Test::More tests => 1;
use Coat::Meta;

{
    package Foo;
    
    sub one { 1 }
    sub two { 2 }

    1;
}

is_deeply([Coat::Meta::_list_all_package_symbols('Foo')], ['one', 'two'],
    "all methods are listed");
