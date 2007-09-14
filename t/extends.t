#!/usr/bin/perl

# classes 

package Point;

use Coat;

var 'x' => ( type => 'Int', default => 0);
var 'y' => ( type => 'Int', default => 0);

package Point3D;

use Coat;
extends 'Point';

var 'z' => ( type => 'Int', default => 0);

# test

package main;

use strict;
use warnings;
use Test::Simple qw(no_plan);

my $point2d = new Point x => 2, y => 4;
ok( defined $point2d, 'new Point');

my $point3d = new Point3D x => 1, y => 3, z => 1;
ok( defined $point3d, 'new Point3D' );

# make sure the father didn't get any attribute property of his son
ok( ( ! $point2d->has('z')), "! \$point2d->can('z')" );

# make sure the son can actually use its particularity
ok( ( $point3d->has('z')), "\$point3d->can('z')" );

# now play with attributes
ok( $point3d->x(3), '$point3d->x(3)' );
ok( $point3d->y(5), '$point3d->x(5)' );
ok( $point3d->z(8), '$point3d->x(8)' );

ok( ($point3d->x == 3), '$point3d->x == 3');
ok( ($point3d->y == 5), '$point3d->x == 5');
ok( ($point3d->z == 8), '$point3d->x == 8');


