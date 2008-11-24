#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('Coat');
}

=pod

This just makes sure that the Bar gets 
a metaclass initialized for it correctly.

=cut

{
    package Foo; 
    use Coat; 

    package Bar; 
    use strict;
    use warnings;
        
    use base 'Foo'; 
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');
