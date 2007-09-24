package Coat::Type::Item::Defined::Value::Str::ClassName;

use strict;
use warnings;

use base 'Coat::Type::Item::Defined::Value::Str';

sub is_valid 
{ 
    my ($class, $classname, $value) = @_;
    
    return (defined $value) && 
           (ref $value) &&
           (ref $value eq $classname);
}

1;
