package Coat::Type::Item::Undef;

use strict;
use warnings;

use base 'Coat::Type::Item';

sub is_valid 
{
    (! defined $_[1])
    ? 1
    : 0
}   

1;
