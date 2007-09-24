package Coat::Type::Item::Defined::Value::Num;

use strict;
use warnings;

use base 'Coat::Type::Item::Defined::Value';

sub is_valid { 
    $_[0]->SUPER::is_valid($_[1]) && 
    ( $_[1] =~ /^[\d\.]*$/ ) 
}

1;
