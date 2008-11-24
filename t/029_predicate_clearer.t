use Test::More 'no_plan';

use strict;
use warnings;

my $REG = {};

{
    package A;
    use Coat;

    has id => (
        is        => 'rw',
        predicate => 'has_id',
        clearer   => 'clear_id',
    );
}

can_ok(A => 'has_id', 'clear_id');
my $a = A->new;
ok(!$a->has_id, "no ID yet");
$a->clear_id;
ok(!$a->has_id, "clearer didn't set ID");

$a->id(1);
is($a->id, 1, "value is set");
ok($a->has_id, "setting the value did set the ID");
$a->clear_id;
is($a->id, undef, "no value after clearer");
ok(!$a->has_id, "running the clearer makes predicate return false");

$a->id(1);
ok($a->has_id, "we have a value again..");

$a->id(undef);
ok($a->has_id, "setting to undef means we still have a value");

$a->clear_id;
ok(!$a->has_id, "clearing from undef still makes predicate false");
is($a->id, undef, "value is still undef");

