#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib', '../lib';

use Test::More tests => 3;

BEGIN {
    use_ok('Coat');           
}

use_ok('MyCoatA');
use_ok('MyCoatB');
