use Test::More tests => 5;

{
    package Point;
    use Coat;

    has x => (isa => 'Num');
    has y => (isa => 'Num');

    sub move {
        my ($self, $x, $y) = @_;
        $self->x($x);
        $self->y($y);
    }
}

my $a = new Point;
$a->move(42, 24);

my $b = $a->make_clone;

isa_ok $b, 'Point';
can_ok $b, qw(x y);
is $b->x, $a->x, 'clone kept the value of x';
is $b->y, $a->y, 'clone kept the value of y';
ok (($a != $b), '$a and $b are not the same objects');

