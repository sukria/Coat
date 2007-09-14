#!/usr/bin/perl

# Classes

package Point;
use Coat;

var 'x' => ( type => 'Int', default => 0);
var 'y' => ( type => 'Int', default => 0);

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

ok( $p1->has( 'x' ), "\$p1->has('x')" );

ok( $p1->x(5), '$p1->x(5)' );
ok( $p1->y(7), '$p1->y(7)' );

ok( ( $p1->x == 5 ) , '$p1->x == 5' );
ok( ( $p1->y == 7 ) , '$p1->y == 7' );

