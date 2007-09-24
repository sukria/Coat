package Coat::Type::Item::Defined::Value;

use strict;
use warnings;

use base 'Coat::Type::Item::Defined';

sub is_valid { 
    $_[0]->SUPER::is_valid($_[1]) && 
    ( ! ref $_[1] ) 
}

1;
