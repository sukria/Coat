use strict;
use warnings;
use Test::More tests => 2;

{
    package Foo;
    use Coat;

    has 't' => (default => sub { 2 + 2 });
}

my $foo = new Foo;
my $time = $foo->t;
ok( !ref $time, "t isn't a ref" );
is($time, 4, 't expands to 4');
