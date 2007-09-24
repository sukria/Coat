package Coat::Type;

use strict;
use warnings;
use Carp 'confess';

sub is_valid   { confess "is_valid Cannot be called from interface Coat::Type" }

1;
