use strict;
use warnings;
use Test::More tests => 17;

BEGIN { use_ok('Coat::Meta')}

{
    package Foo;
    use Coat;
    has 'field_from_foo_string' => (
        isa => 'Str'
    );
    has 'field_from_foo_int' => (
        isa => 'Int',
        default => 1,
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

    package Biz;
    use Coat;
    has 'field_from_biz';

    package BalBaz;
    use Coat;
    extends qw(Bar Biz);
}

my @foo_family    = qw(Coat::Object);
my @bar_family    = qw(Coat::Object Foo);
my @baz_family    = qw(Coat::Object Foo Bar);
my @balbaz_family = qw(Coat::Object Foo Bar Biz);

is_deeply(Coat::Meta->family( 'Foo' ), \@foo_family,
    qq/Foo's family is correct/);
is_deeply(Coat::Meta->family( 'Bar' ), \@bar_family,
    qq/Bar's family is correct/);
is_deeply(Coat::Meta->family( 'Baz' ), \@baz_family,
    qq/Baz's family is correct/);
is_deeply(Coat::Meta->family( 'BalBaz' ), \@balbaz_family,
    qq/BalBaz's family is correct/);

my $foo = Coat::Meta->all_attributes( 'Foo' );
my $bar = Coat::Meta->all_attributes( 'Bar' );
my $baz = Coat::Meta->all_attributes( 'Baz' );
my $bal = Coat::Meta->all_attributes( 'BalBaz' );

ok(defined $foo && ref($foo), 'Coat::Meta->all_attributes for Foo');
ok(defined $bar && ref($bar), 'Coat::Meta->all_attributes for Bar');
ok(defined $baz && ref($baz), 'Coat::Meta->all_attributes for Baz');
ok(defined $bal && ref($bal), 'Coat::Meta->all_attributes for BalBaz');

is(keys %{ $foo }, 2,
    'Foo has the correct number of attributes');

is(keys %{ $bar }, 3,
    'Baz has the correct number of attributes');

is(keys %{ $baz }, 4,
    'Baz has the correct number of attributes');

is(keys %{ $bal }, 4,
    'BalBaz has the correct number of attributes');

is($baz->{'field_from_foo_int'}{'isa'}, 'Int',
    qq/Baz kept the isa for Foo's field_from_foo_int/);

my $b = new Baz;
is($b->field_from_foo_int, 2,
    qq/default value has been overwritten for Foo's field_from_foo_int/);

my $attr = Coat::Meta->attribute( 'Foo', 'field_from_foo_string' );
ok( defined $attr, 'attribute field_from_foo_string is known' );

eval { Coat::Meta->attribute('Foo', 'doesnotexist'); };
ok ($@, "Illegal call to Coat::Meta->attribute detected" );

