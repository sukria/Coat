use Test::More 'no_plan';
use strict;
use warnings;

sub time_to_datetime($) {
    my $time = shift;
    my ($sec, $min, $hour, $day, $mon, $year) = localtime($time);
    $mon++;
    $year += 1900;
    $sec = sprintf('%02d', $sec);
    $min = sprintf('%02d', $min);
    $hour = sprintf('%02d', $hour);
    $mon = sprintf('%02d', $mon);
    $day = sprintf('%02d', $day);
    return "${year}-${mon}-${day} ${hour}:${min}:${sec}";
}

# Types & Coercions
BEGIN { use_ok 'Coat::Types' }

subtype 'Date'
    => as 'Str'
    => where { /^\d\d\d\d-\d\d-\d\d$/ };

subtype 'DateTime'
    => as 'Str'
    => where { /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/ };

coerce 'DateTime'
    => from 'Int'
    => via { time_to_datetime($_) };

coerce 'DateTime'
    => from 'Date'
    => via { "$_ 00:00:00" };

{
    package Foo;
    use Coat;

    has 'date' => (
        is => 'rw',
        isa => 'Date',
    );

    has 'date_time' => (
        is => 'rw',
        isa => 'DateTime',
        coerce => 1,
    );
}

# fixtures
my $date      = '2008-09-12';
my $date_time =  '2008-09-12 00:00:00';

my $o = Foo->new;
is( $date, $o->date($date), "date set to $date" );
ok( $o->date_time($o->date), 'coerce date_time from date' );
is( $date_time, $o->date_time, 'date_time correctly coerced' );

ok( $o->date_time( time ), 'coerce from Int' );
