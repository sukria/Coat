#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Scalar::Util 'blessed';

use Coat::Types;

subtype 'Positive'
     => as 'Num'
     => where { $_ > 0 };

{
    package Parent;
    use Coat;

    has name => (
        is       => 'rw',
        isa      => 'Str',
    );

    has lazy_classname => (
        is      => 'ro',
        lazy    => 1,
        default => sub { "Parent" },
    );

    has type_constrained => (
        is      => 'rw',
        isa     => 'Positive',
        default => 5.5,
    );

    package Child;
    use Coat;
    extends 'Parent';

    has '+name' => (
        default => 'Junior',
    );

    has '+lazy_classname' => (
        default => sub { "Child" },
    );

    has '+type_constrained' => (
        isa     => 'Int',
        default => 100,
    );
}

my $foo = Parent->new;
my $bar = Child->new;

my $attr = Coat::Meta->has( 'Parent', 'type_constrained');
is( $attr->{isa}, 'Positive', 'Parent type_constrained isa Positive');

is(blessed($foo), 'Parent', 'Parent->new gives a Parent object');
is($foo->name, undef, 'No name yet');
is($foo->lazy_classname, 'Parent', "lazy attribute initialized");

eval { $foo->type_constrained(10.5) };
is $@, '', "Num type constraint for now..";

eval { $foo->type_constrained(10) };
is $@, '', "10 passes the Positive type-constraint";

is($bar->name, 'Junior', "Child->name's default came through");

is($foo->lazy_classname, 'Parent', "lazy attribute was already initialized");

is(blessed($bar), 'Child', 'successfully reblessed into Child');

$attr = Coat::Meta->has( 'Child', 'type_constrained');
is( $attr->{isa}, 'Int', 'Child type_constrained isa Int');

is($bar->lazy_classname, 'Child', "lazy attribute just now initialized");
is( $bar->type_constrained, 100, 'default value is overiden');

eval { $bar->type_constrained(5) };
is $@, '', "5 passes the Int type-constraint";

eval { $bar->type_constrained(10.5) };
like $@, qr/^Value '10.5' does not validate type constraint 'Int'/,
'... this failed cause of type check';

