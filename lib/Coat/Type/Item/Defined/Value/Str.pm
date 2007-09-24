package Coat::Type::Item::Defined::Value::Str;

use strict;
use warnings;

use base 'Coat::Type::Item::Defined::Value';

sub is_valid { 
    $_[0]->SUPER::is_valid($_[1])
}

1;
