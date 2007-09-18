use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok('Coat');
}

my @list;
my @expected = ('before1:Perl', 
                'before2:Perl',
                'before3:Perl',
                'around2:Perl',
                'around:before:Perl', 'Perl', 'around:after:Perl',
                'around3:Perl',
                'after1:Perl',
                'after2:Perl',
                'after3:Perl',
                );
{
    package Parent;
    use Coat;

    sub pushelem { push @list, $_[1] }

    package Child;
    use Coat;
    extends 'Parent';

    before 'pushelem' => sub {
        my ($self, $elem) = @_;
        push @list, "before1:$elem";
    };

    before 'pushelem' => sub {
        my ($self, $elem) = @_;
        push @list, "before2:$elem";
    };

    before 'pushelem' => sub {
        my ($self, $elem) = @_;
        push @list, "before3:$elem";
    };

    after 'pushelem' => sub {
        my ($self, $elem) = @_;
        push @list, "after1:$elem";
    };

    around 'pushelem' => sub {
        my $orig = shift;
        my ($self, $elem) = @_;
        push @list, "around:before:$elem";
        $self->$orig($elem);
        push @list, "around:after:$elem";
    };

    around 'pushelem' => sub {
        my $orig = shift;
        my ($self, $elem) = @_;
        push @list, "around2:$elem";
        $self->$orig($elem);
    };

    around 'pushelem' => sub {
        my $orig = shift;
        my ($self, $elem) = @_;
        $self->$orig($elem);
        push @list, "around3:$elem";
    };

    after 'pushelem' => sub {
        my ($self, $elem) = @_;
        push @list, "after2:$elem";
    };

    after 'pushelem' => sub {
        my ($self, $elem) = @_;
        push @list, "after3:$elem";
    };

}

my $parent = new Parent;
isa_ok($parent, 'Parent');

my $child  = new Child;
isa_ok($child, 'Child');

@list = ();
$parent->pushelem('Perl');
is_deeply(\@list, ['Perl'], 'Parent pushed correctly');

@list = ();
$child->pushelem('Perl');
is_deeply(\@list, \@expected, 'Child pushed correctly');

