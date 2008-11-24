use strict;
use warnings;
use Test::More 'no_plan';

{
    package Foo;
    use Coat;

    has 'x' => ( isa => 'Int');
    has 's' => ( isa => 'Str', required => 1);

    has 'a' => ( isa => 'ArrayRef');
    has 'h' => ( isa => 'HashRef');
    has 'c' => ( isa => 'CodeRef');
    
    has 'subobject' => ( isa => 'Bar' );

    package Bar;
    use Coat;

    has 'x';

    package Baz;
    use Coat;
}

my $foo = new Foo;

# valid calls
ok( $foo->x(43), 'foo->x allows integers' );
ok( $foo->s(43), 'foo->s allows integers' );
ok( $foo->s("message Perl Moose Coat"), 'foo->s allows strings' );
ok( $foo->a( [1, 4, 6]), "foo->a allows array references" );
ok( $foo->c(sub { 3 }), "foo->a allows code references" );
ok( $foo->subobject(new Bar), 'foo->subobject allows class reference');

# invalid calls
eval { $foo->x("string") };
ok( $@, "foo->x does not allow strings");

eval { $foo->s(undef) };
ok( $@, 'undef values are not allowed for required String' );

eval { $foo->a(43) };
ok( $@, 'ArrayRef does not allow non ref values' );

eval { $foo->a({a => 1, b => 2}) };
ok( $@, 'ArrayRef does not allow Hash references' );

eval { $foo->c({a => 1, b => 2}) };
ok( $@, 'CodeRef does not allow Hash references' );

eval { $foo->subobject(new Baz) };
ok( $@, 'foo->subobject does not allow Baz' );


