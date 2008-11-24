use Test::More 'no_plan';

BEGIN { use_ok 'Coat' }
{
    package Foo;
    use Coat;

    has 'field' => (isa => 'Str');
}

my $f = Foo->new( field => undef );
is( undef, $f->{field}, 'field is not defined' );


