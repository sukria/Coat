use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Coat') }

my $flag = 0;

{
    package MyObject;
    use Coat;

    package MyObjectAltered;
    use Coat;

    after 'new' => sub { $flag = 1 };
}

my $o = new MyObject;

is(0, $flag, '$flag is untouched when new MyObject');
isa_ok( $o, 'Coat::Object' );
isa_ok( $o, 'MyObject' );

my $o2 = new MyObjectAltered;
isa_ok( $o2, 'Coat::Object' );
isa_ok( $o2, 'MyObjectAltered' );
is(1, $flag, '$flag is touched when new MyObjectAltered');

