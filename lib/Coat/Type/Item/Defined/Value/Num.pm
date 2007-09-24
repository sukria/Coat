package Coat::Type::Item::Defined::Value::Num;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use base 'Coat::Type::Item::Defined::Value';

sub is_valid { $_[0]->SUPER::is_valid($_[1]) && looks_like_number( "$_[1]" ) }

1;
