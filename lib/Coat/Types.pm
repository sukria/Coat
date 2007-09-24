package Coat::Types;

use strict;
use warnings;
use Carp 'confess';

use Coat::Type::Any;
use Coat::Type::Item;
use Coat::Type::Item::Bool;
use Coat::Type::Item::Undef;
use Coat::Type::Item::Defined;
use Coat::Type::Item::Defined::Value;
use Coat::Type::Item::Defined::Value::Num;
use Coat::Type::Item::Defined::Value::Num::Int;
use Coat::Type::Item::Defined::Value::Str;
use Coat::Type::Item::Defined::Value::Str::ClassName;
use Coat::Type::Item::Defined::Ref;
use Coat::Type::Item::Defined::Ref::ScalarRef;
use Coat::Type::Item::Defined::Ref::ArrayRef;
use Coat::Type::Item::Defined::Ref::HashRef;
use Coat::Type::Item::Defined::Ref::CodeRef;

sub validate
{
    my ($class, $isa, $attribute, $value) = @_;
    my $isa_class = {
        Any       => 'Coat::Type::Any',
        Item      => 'Coat::Type::Item',
        Bool      => 'Coat::Type::Item::Bool',
        Undef     => 'Coat::Type::Item::Undef',
        Defined   => 'Coat::Type::Item::Defined',
        Value     => 'Coat::Type::Item::Defined::Value',
        Num       => 'Coat::Type::Item::Defined::Value::Num',
        Int       => 'Coat::Type::Item::Defined::Value::Num::Int',
        Str       => 'Coat::Type::Item::Defined::Value::Str',
        ClassName => 'Coat::Type::Item::Defined::Value::Str::ClassName',
        Ref       => 'Coat::Type::Item::Defined::Ref',
        ScalarRef => 'Coat::Type::Item::Defined::Ref::ScalarRef',
        ArrayRef  => 'Coat::Type::Item::Defined::Ref::ArrayRef',
        HashRef   => 'Coat::Type::Item::Defined::Ref::HashRef',
        CodeRef   => 'Coat::Type::Item::Defined::Ref::CodeRef',
        RegexpRef => 'Coat::Type::Item::Defined::Ref::RegexpRef',
    };

    if (exists $isa_class->{$isa}) {
        my $type = $isa_class->{$isa};
        $type->is_valid($value) 
            or confess "Value '"
                .(defined $value ? $value : 'undef')
                ."' does not validate type constraint '$isa' "
                . "for attribute '$attribute'";
    }
    
    # unknown type, use it as a classname
    else {
        my $classname = $isa;
        $isa = $isa_class->{'ClassName'};
        $isa->is_valid($classname, $value) 
            or confess "Value '"
                . (defined $value ? $value : 'undef')
                . " is not a member of class '$classname' "
                . "for attribute '$attribute'";
    }
}

1;
