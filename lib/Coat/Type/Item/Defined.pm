package Coat::Type::Item::Defined;

use strict;
use warnings;

use base 'Coat::Type::Item';

sub is_valid {
    (defined $_[1])
    ? 1
    : 0
}

1;
