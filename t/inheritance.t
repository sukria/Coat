package Person;
use Coat;

var 'name' => (
    type => 'String',
);

var 'force' => (
    type => 'Int',
    default => 1
);

sub walk
{
    my ($self) = @_;
    return $self->name . " walks\n";
}

package Soldier;
use Coat;
extends 'Person';

var 'force' => (
    type => 'Int',
    default => 3
);

sub attack
{
    my ($self) = @_;
    return $self->force + int(rand(10));
}

package General;
use Coat;
extends 'Soldier';

var 'force' => (
    type => 'Int',
    default => '5'
);

package main;

use strict;
use warnings;

use Test::Simple qw(no_plan);

my $man = new Person name => 'John';
my $soldier = new Soldier name => 'Dude';
my $general = new General name => 'Smith';

ok(defined $man, 'new Person');
ok(defined $soldier, 'new Soldier');
ok(defined $general, 'new General');

ok($man->has('name'), '$man->has(name)');
ok($man->has('force'), '$man->has(force)');
ok($soldier->has('name'), '$soldier->has(name)');
ok($soldier->has('force'), '$soldier->has(force)');
ok($general->has('name'), '$general->has(name)');
ok($general->has('force'), '$general->has(force)');

ok($man->force == 1, '$man->force == 1');
ok($soldier->force == 3, '$soldier->force == 3');
ok($general->force == 5, '$general->force == 5');

ok($man->walk, '$man->walk');
ok($soldier->walk, '$soldier->walk');
ok($general->walk, '$general->walk');

ok($soldier->attack, '$soldier->attack');
ok($general->attack, '$general->attack');
