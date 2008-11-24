use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok 'Coat' }

{
    package Foo;
    use Coat;

    has 'bar' => (
        is => 'rw', 
        trigger => sub {
            my ($self, $value) = @_;
            $self->number($value);
        }
    );
    has number => (is => 'Int');
}

eval {
    package Bar;
    use Coat;

    has badtrig => (is => 'Int', trigger => 1);
};
ok($@, 'Unable to build a class with a non-ref value as a trigger');

eval {
    package Baz;
    use Coat;

    has badtrig => (is => 'Int', trigger => []);
};
ok($@, 'Unable to build a class with a non code-ref value as a trigger');

my $foo = new Foo number => 42;
isa_ok($foo, 'Foo');
is($foo->number, 42, '$foo->number is set to 42');

$foo->bar(33);
is($foo->bar, 33, '$foo->bar is set to 33');
is($foo->number, 33, '$foo->number is set to 33');

