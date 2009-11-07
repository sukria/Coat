use Test::More tests => 4;

eval { 
    package Baz;
    use Coat;
    alias foo => 'bar';
};
like $@, qr/cannot alias undefined method \"bar\"/,
    "alias does not work with invalid method name";

{
    package Foo;
    use Coat;

    sub foo { "foo" }
    alias bar => 'foo';
}

my $f = Foo->new;
isa_ok $f, 'Foo';
can_ok $f, qw(foo bar);
is $f->bar, $f->foo, "method bar returned the same value as method foo";
