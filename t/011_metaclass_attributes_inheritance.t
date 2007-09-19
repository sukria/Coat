use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Coat::Meta')}

{
    package Foo;
    use Coat;
    has 'field_from_foo_string' => (
        type => 'String'
    );
    has 'field_from_foo_int' => (
        type => 'Int',
        default => 1
    );

    package Bar;
    use Coat;
    extends 'Foo';
    has 'field_from_bar';

    package Baz;
    use Coat;
    extends 'Bar';
    has 'field_from_baz';
    # we redefine an attribute of an inherited class
    has 'field_from_foo_int' => (
        default => 2
    );
}

my @foo_family = qw(Coat::Object);
my @bar_family = qw(Coat::Object Foo);
my @baz_family = qw(Coat::Object Foo Bar);

is_deeply(Coat::Meta->family( 'Foo' ), \@foo_family,
    qq/Foo's family is correct/);
is_deeply(Coat::Meta->family( 'Bar' ), \@bar_family,
    qq/Bar's family is correct/);
is_deeply(Coat::Meta->family( 'Baz' ), \@baz_family,
    qq/Baz's family is correct/);

my $foo = Coat::Meta->all_attributes( 'Foo' );
my $bar = Coat::Meta->all_attributes( 'Bar' );
my $baz = Coat::Meta->all_attributes( 'Baz' );

ok(defined $foo && ref($foo), 'Coat::Meta->all_attributes for Foo');
ok(defined $bar && ref($bar), 'Coat::Meta->all_attributes for Bar');
ok(defined $baz && ref($baz), 'Coat::Meta->all_attributes for Baz');

is(keys %{ $foo }, 2,
    'Foo has the correct number of attributes');

is(keys %{ $bar }, 3,
    'Baz has the correct number of attributes');

is(keys %{ $baz }, 4,
    'Baz has the correct number of attributes');

is($baz->{'field_from_foo_int'}{'type'}, 'Int',
    qq/Baz kept the type for Foo's field_from_foo_int/);

is($baz->{'field_from_foo_int'}{'default'}, 2,
    qq/default value has been overwritten for Foo's field_from_foo_int/);

#use Data::Dumper;
#print Dumper($baz);
#print Dumper(Coat::Meta->classes);
