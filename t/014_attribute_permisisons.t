use strict;
use warnings;
use Test::More 'no_plan';

{
    package Foo;
    use Coat;

    has 'read' => (
        is => 'ro', 
        default => 2, 
        isa => 'Int'
    );

    has 'write' => (
        is => 'rw',
        default => 3,
        isa => 'Int'
    );

    has 'def';
}

my $foo = new Foo;
is($foo->read, 2, 'attr read is readable');

