use strict;
use warnings;
use Test::Simple qw(no_plan);
use Coat::Meta;

{
    package Person;
    use Coat;

    has 'name' => ( isa => 'Str'); 
    has 'force' => ( isa => 'Int', default => 1);

    sub walk {
        my ($self) = @_;
        return $self->name . " walks\n";
    }

    package Soldier;
    use Coat;
    extends 'Person';

    has 'force' => ( isa => 'Int', default => 3);

    sub attack {
        my ($self) = @_;
        return $self->force + int(rand(10));
    }

    package General;
    use Coat;
    extends 'Soldier';

    has 'force' => ( isa => 'Int', default => '5');

    # just to make sur we can hook something inherited
    before walk => sub {
        return 1;
    };
}


my $man = new Person name => 'John';
my $soldier = new Soldier name => 'Dude';
my $general = new General name => 'Smith';

ok(defined $man, 'new Person');
ok(defined $soldier, 'new Soldier');
ok(defined $general, 'new General');

ok(Coat::Meta->has(ref($man), 'name'), '$man->has_attr(name)');
ok(Coat::Meta->has(ref($man), 'force'), '$man->has_attr(force)');
ok(Coat::Meta->has(ref($soldier), 'name'), '$soldier->has_attr(name)');
ok(Coat::Meta->has(ref($soldier), 'force'), '$soldier->has_attr(force)');
ok(Coat::Meta->has(ref($general), 'name'), '$general->has_attr(name)');
ok(Coat::Meta->has(ref($general), 'force'), '$general->has_attr(force)');

ok($man->force == 1, '$man->force == 1');
ok($soldier->force == 3, '$soldier->force == 3');
ok($general->force == 5, '$general->force == 5');

ok($man->walk, '$man->walk');
ok($soldier->walk, '$soldier->walk');
ok($general->walk, '$general->walk');

ok($soldier->attack, '$soldier->attack');
ok($general->attack, '$general->attack');
