package MyObject;
use Coat;

package main;
use strict;
use warnings;
use Test::More 'no_plan';

my $o = new MyObject;

isa_ok( $o, 'Coat::Object' );
isa_ok( $o, 'MyObject' );
