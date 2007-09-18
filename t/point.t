#!/usr/bin/perl

# Classes

package Point;
use Coat;

has 'x' => ( type => 'Int', default => 0);
has 'y' => ( type => 'Int', default => 0);

1;

# Test

package main;

use strict;
use warnings;

use Test::Simple qw(no_plan);

my $p1 = new Point;
ok( defined $p1, 'new Point' );
ok( ( $p1->x == 0 ), '$p1->x == 0 ' );
ok( ( $p1->y == 0 ), '$p1->y == 0 ' );

eval { $p1->x("toto"); };
ok( $@, "x cannot be set to a string" );

ok( $p1->has_attr( 'x' ), "\$p1->has_attr('x')" );

ok( $p1->x(5), '$p1->x(5)' );
ok( $p1->y(7), '$p1->y(7)' );

ok( ( $p1->x == 5 ) , '$p1->x == 5' );
ok( ( $p1->y == 7 ) , '$p1->y == 7' );

