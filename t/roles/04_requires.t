use Test::More tests => 2;

{
    package Foo::Role;
    use Coat::Role;
    requires 'foo', 'bar', 'baz';
}

eval {
    package Foo::Class1;
    use Coat;
    with 'Foo::Role';
};

like $@, 
     qr/Methods foo, bar, baz are required by the role Foo::Role/,
     "required methods are checked when a role is used";

eval {
    package Foo::Class2;
    use Coat;
    with 'Foo::Role';

    sub foo { 'foo' }
    sub bar { 'bar' };
    sub baz { 'baz' };
};

is $@, '', 'Foo::Class2 implements correctly the role Foo::Role';
