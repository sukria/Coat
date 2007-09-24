package Coat::Type::Item::Defined::Ref;

use strict;
use warnings;

use base 'Coat::Type::Item::Defined';

sub is_valid { 
    my ($class, $value) = @_;    
    ($class->SUPER::is_valid($value))
    ? ((ref $value)
        ? 1
        : 0)
    : 0
}

1;
