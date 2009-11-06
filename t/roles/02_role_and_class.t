use Test::More tests => 6;

{
    package Breakable;
    use Coat::Role;
    has is_broken => (isa => 'Bool', default => 0);

    sub break { shift->is_broken(1) }

    package Window;
    use Coat; 
    with 'Breakable';
}

my $w = Window->new;
ok defined($w), 'Coat object is defined';
isa_ok $w, 'Window';
can_ok $w, qw(is_broken break);

is($w->is_broken, 0, 'is_broken is false');
ok($w->break, 'break is called');
is($w->is_broken, 1, 'is_broken has been set');
