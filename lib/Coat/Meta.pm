package Coat::Meta;

use strict;
use warnings;
use Carp 'confess';
use vars qw($VERSION $AUTHORITY);

$VERSION   = '0.1_0.4';
$AUTHORITY = 'cpan:SUKRIA';

# This is the classes placeholder for attribute descriptions
my $CLASSES = {};

# the root accessor: returns the whole data structure, all meta classes
sub classes { $CLASSES }

sub attributes { $CLASSES->{ $_[1] } }
sub declare 
{ 
    my ($self, $class) = @_;
    
    $CLASSES->{ $class } ||= {};
    
    $CLASSES->{'@!parents'}{ $class } = [] 
        unless defined $CLASSES->{'@!parents'}{ $class };
    
    $CLASSES->{'@!family'}{ $class } = [] 
        unless defined $CLASSES->{'@!family'}{ $class };

    return $CLASSES->{ $class };
}

# define an attribute for a class,
# takes care to propagate default values from parents to 
# children
sub attribute 
{
    my ($self, $class, $attribute, $value) = @_;
    
    # we define the attribute for the class
    if (@_ == 4) {
        return $CLASSES->{ $class }{ $attribute } = $value;
    }

    # we have to return the attribute description
    # either from ourselves, or from our parents
    else {
        my $desc = Coat::Meta->has( $class, $attribute ); 
        return $desc if defined $desc;

        confess "Attribute $attribute was not previously declared ".
                "for class $class";
    }
}

sub exists
{ 
    my ($self, $class) = @_;
    return exists $CLASSES->{ $class };
}

# this method looks for the attribute description in the whole hierarchy 
# of the class, starting by the lowest leaf.
# returns the description or undef if not found.
sub has($$$);
sub has($$$)
{ 
    my ($self, $class, $attribute) = @_;


    # if the attribute is declared for us, it's ok
    return $CLASSES->{ $class }{ $attribute } if 
        exists $CLASSES->{ $class }{ $attribute };

    # else, we'll look inside each of our parents, recursively
    # until we stop or find one ancestor with the atttribute
    foreach my $parent (Coat::Meta->parents( $class )) {
        my $parent_attr = Coat::Meta->has( $parent, $attribute );
        return $parent_attr if defined $parent_attr;
    }

    # none found, the attribute is not supported by the family 
    return undef;
}

# This will build the attributes for a class with all inherited attributes
sub all_attributes($$;$);
sub all_attributes($$;$)
{
    my ($self, $class, $hash) = @_;
    $hash = {} unless defined $hash;

    # start with the parents so we can overwrite their attrs
    foreach my $parent (Coat::Meta->parents( $class ) ) {
        $hash = Coat::Meta->all_attributes($parent, $hash);
    }
    
    $hash = { %{ $hash }, %{ Coat::Meta->attributes( $class ) } };

    return $hash;
}

sub is_family 
{ 
    my ($self, $class, $parent) = @_;
    return grep /^$parent$/, @{$CLASSES->{'@!family'}{ $class }};
}

sub is_parent 
{ 
    my ($self, $class, $parent) = @_;
    return grep /^$parent$/, @{$CLASSES->{'@!parents'}{ $class }};
}

sub family { $CLASSES->{'@!family'}{ $_[1] } }

sub extends 
{ 
    my ($self, $class, $parents) = @_;
    $parents = [$parents] unless ref $parents;
    
    foreach my $parent (@$parents) {
        # make sure we don't inherit twice
        confess "Class '$class' already inherits from class '$parent'" if 
            Coat::Meta->is_family( $class, $parent );
        
        push @{ $CLASSES->{'@!parents'}{ $class } }, $parent;

        # init the family list
        $CLASSES->{'@!family'}{ $class } = [
            @{ $CLASSES->{'@!family' }{ $class  } },
            @{ $CLASSES->{'@!parents'}{ $parent } },
            ];
        

        push @{$CLASSES->{'@!family'}{ $class }}, $parent unless 
            Coat::Meta->is_family( $class, $parent )}
}

# returns all the classes the class inherits from (extends '')
sub parents 
{ 
    my ($self, $class) = @_;
    $class = caller unless defined $class;

    return wantarray 
        ? @{ $CLASSES->{'@!parents'}{ $class } }
        : $CLASSES->{'@!parents'}{ $class };
}

sub modifiers
{ 
    my ($self, $hook, $class, $method, $coderef) = @_;

    # init the method modifiers placeholder
    $CLASSES->{'%!hooks'}{ $class }{ $hook }{ $method } = [] unless
        defined $CLASSES->{'%!hooks'}{ $class }{$hook}{ $method };
     
    # wants to push a new coderef 
    if (defined $coderef) {
        push @{ $CLASSES->{'%!hooks'}{ $class }{$hook}{ $method } }, $coderef;
        return $coderef;
    }

    # wants to get the hooks
    else {
        return $CLASSES->{'%!hooks'}{ $class }{$hook}{ $method } ||= [];
    }
}

sub around_modifiers { shift and Coat::Meta->modifiers('around', @_ ) }
sub after_modifiers  { shift and Coat::Meta->modifiers('after', @_ ) }
sub before_modifiers { shift and Coat::Meta->modifiers('before', @_ ) }

1;
__END__
