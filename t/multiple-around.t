use strict;
use warnings;
use Test::More tests => 1;

my @seen;
my @expected = ("around 2 before", "around 1 before", "orig", "around 1 after", "around 2 after");

my $child = Child->new; $child->orig;

is_deeply(\@seen, \@expected, "multiple arounds called in the right order");

BEGIN {
    package Parent;
    use Coat;

    sub orig
    {
        print "# dans orig : received: ".join(',', @_)."\n";
        push @seen, "orig";
        print "# FIN orig\n";
    }
}

BEGIN {
    package Child;
    use Coat;
    extends 'Parent';

    around orig => sub
    {
        print "# dans around 1 : received: ".join(',', @_)."\n";
        my $orig = shift;
        die "around #1 : no orig hook given" unless defined $orig;

        push @seen, "around 1 before";
        $orig->();
        push @seen, "around 1 after";
        print "# FIN around 1\n";
    };

    around orig => sub
    {
        print "# dans around 2 : received: ".join(',', @_)."\n";
        my $orig = shift;
        die "around #2 : no orig hook given" unless defined $orig;

        push @seen, "around 2 before";
        $orig->();
        push @seen, "around 2 after";
        print "# FIN around 2\n";
    };
}

