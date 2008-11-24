#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use Coat::Types;

=pod

This tests demonstrates that Coat will not override 
a pre-existing type constraint of the same name when 
making constraints for a Coat-class.

It also tests that an attribute which uses a 'Foo' for
it's isa option will get the subtype Foo, and not a 
type representing the Foo moose class.

=cut

BEGIN { 
    # create this subtype first (in BEGIN)
    subtype Foo 
        => as 'Value' 
        => where { $_ eq 'Foo' };
}

{ # now seee if Coat will override it
    package Foo;
    use Coat;
}

my $foo_constraint = find_type_constraint('Foo');
isa_ok($foo_constraint, 'Coat::Meta::TypeConstraint');

is($foo_constraint->parent, 'Value', '... got the Value subtype for Foo');

{
    package Bar;
    use Coat;
    
    has 'foo' => (is => 'rw', isa => 'Foo');
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');

lives_ok {
    $bar->foo('Foo');       
} '... checked the type constraint correctly';

dies_ok {
    $bar->foo(Foo->new);       
} '... checked the type constraint correctly';



