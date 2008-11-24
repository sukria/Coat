use strict;
use warnings;
use Test::More tests => 1;

{
    package Foo;
    use Coat;
    has var => (isa => 'Int', default => 1);

    sub BUILD
    {
        my ($self) = @_;
        use Data::Dumper;
        $self->var(2);
    }
}

my $foo = new Foo;
is( $foo->var, 2, 'BUILD has been called properly' );
