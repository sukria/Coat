use Test::More tests => 2;
use strict;

{
    package Spanish;
    use Coat;

    has uno => (
        is      => 'ro',
        default => sub {
            return 1;
        }
    );

    has dos => (
        is      => 'ro',
        default => sub {
            return 2;
        }
    );

    package English;
    use Coat;

    has translate => (
        is      => 'ro',
        default => sub {
            return Spanish->new;
        },
        handles => {
            one => 'uno',
            two => 'dos',
        }
    );
}

my $eng = English->new;

is $eng->one, 1, 'one';
is $eng->two, 2, 'two';

