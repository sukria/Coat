package Coat::Type::Item::Bool;

use strict;
use warnings;

use base 'Coat::Type::Item';

# A boolean must be defined and equal to 0 or 1
sub is_valid { 
    (defined $_[1]) 
    ? ( ($_[1] == 0 || $_[1] == 1) 
        ? 1
        : 0)
    : 0
}

1;
