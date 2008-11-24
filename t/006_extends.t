#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;
use Coat::Meta;

use lib 't';

# classes 
{
    package MyItem;
    use Coat;
    has name => (isa => 'Str');

    package MyItem3D;
    use Coat;
    extends qw(Point3D MyItem);
}

my $point2d = new Point x => 2, y => 4;
isa_ok($point2d, 'Point');

my $point3d = new Point3D x => 1, y => 3, z => 1;
isa_ok($point3d, 'Point3D');

my $item = new MyItem3D name => 'foo', x => 4, z => 3;
isa_ok($item, 'MyItem3D');
isa_ok($item, 'Point3D');
isa_ok($item, 'MyItem');

# make sure the father didn't get any attribute property of his son
ok( ( ! Coat::Meta->has(ref($point2d), 'z')), "! \$point2d->can('z')" );

# make sure the son can actually use its particularity
ok( ( Coat::Meta->has(ref($point3d), 'z')), "\$point3d->can('z')" );

# now play with attributes
ok( $point3d->x(3), '$point3d->x(3)' );
ok( $point3d->y(5), '$point3d->x(5)' );
ok( $point3d->z(8), '$point3d->x(8)' );

ok( ($point3d->x == 3), '$point3d->x == 3');
ok( ($point3d->y == 5), '$point3d->x == 5');
ok( ($point3d->z == 8), '$point3d->x == 8');

