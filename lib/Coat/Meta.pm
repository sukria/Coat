package Coat::Meta;

use strict;
use warnings;
use Carp 'confess';
use Scalar::Util 'reftype';

# This is the classes placeholder for attribute descriptions
my $CLASSES = {};
my $ROLES   = {};

# the root accessor: returns the whole data structure, all meta classes
sub classes { $CLASSES }

# returns all attributes for the given class
sub attributes { $CLASSES->{ $_[1] } || {} }

# returns the meta-data for the given class
sub class
{ 
    my ($self, $class) = @_;
    
    $CLASSES->{ $class } ||= {};
    
    $CLASSES->{'@!family'}{ $class } = [] 
        unless defined $CLASSES->{'@!family'}{ $class };

    return $CLASSES->{ $class };
}

# define an attribute for a class,
# takes care to propagate default values from parents to 
# children
sub attribute 
{
    my ($self, $class, $attribute, $attr_desc) = @_;
        
    # the attribute description may already exist 
    my $desc = Coat::Meta->has( $class, $attribute ); 
    
    # we define the attribute for the class
    if (@_ == 4) {
        $desc = {} unless defined $desc;

        # default values for attribute description
        $desc->{isa} = 'Any' unless exists $desc->{isa};
        $desc->{is}  = 'rw'  unless exists $desc->{is};

        # if a trigger is set, must be a coderef
        if (defined $attr_desc->{'trigger'}) {
            my $trigger = $attr_desc->{'trigger'};
            confess "The trigger option must be passed a code reference" 
                unless ref $trigger && (ref $trigger eq 'CODE');
        }

        # check attribute description
        if (defined $desc->{default}) {
            if (( ref($desc->{default})) && 
                ('CODE' ne reftype($desc->{default}))) {
                confess "Default must be a code reference or a simple scalar for "
                        . "attribute '$attribute' : ".$desc->{default};
            }
        }

        return $CLASSES->{ $class }{ $attribute } = { %{$desc}, %{$attr_desc}};
    }

    # we have to return the attribute description
    # either from ourselves, or from our parents
    else {
        return $desc if defined $desc;
        confess "Attribute $attribute was not previously declared ".
                "for class $class";
    }
}

# kindly stolen from Class::MOP
sub _get_namespace_for_class {
    my ($class) = @_;
    { 
        no strict 'refs';
        return \%{$class . '::'};
    }
}

sub _list_all_package_symbols {
    my ($class, $type_filter) = @_; 

    my $namespace = _get_namespace_for_class($class);
    return keys %{$namespace} unless defined $type_filter;
        
    # NOTE:
    # or we can filter based on 
    # type (SCALAR|ARRAY|HASH|CODE)
    if ( $type_filter eq 'CODE' ) { 
        return grep { 
        (ref($namespace->{$_})
                ? (ref($namespace->{$_}) eq 'SCALAR')
                : (ref(\$namespace->{$_}) eq 'GLOB'
                   && defined(*{$namespace->{$_}}{CODE})));
        } keys %{$namespace};
    } else {
        return grep { *{$namespace->{$_}}{$type_filter} } keys %{$namespace};
    }
}

sub compose_class_with_role {
    my ($self, $class, $role) = @_;
    $CLASSES->{$class} = $CLASSES->{$role};
    
    # attributes
    foreach my $attr (keys %{$CLASSES->{$class}}) {
        my $code = Coat::_accessor_for_attr($attr);
        Coat::_bind_coderef_to_symbol($code, "${class}::${attr}");
    }

    # methods
    foreach my $method (_list_all_package_symbols($role, 'CODE')) {
        next if grep /^$method$/, @Coat::Role::EXPORT;
        { 
            no strict 'refs';
            *{"${class}::${method}"} = *{"${role}::${method}"}
        }
    }
    return 1;
}

sub role_register_required_methods {
    my ($self, $role, @methods) = @_;
    $ROLES->{$role} ||= {};
    $ROLES->{$role}{required} = \@methods;
}

sub role_get_required_methods {
    my ($self, $role) = @_;
    $ROLES->{$role} ||= {};
    $ROLES->{$role}{required} ||= [];
    @{ $ROLES->{$role}{required} };
}

sub exists
{ 
    my ($self, $class) = @_;
    return exists $CLASSES->{ $class };
}

# returns the default value for the given $class/$attr
sub attr_default($$) {
    my( $self, $obj, $attr) = @_;
    my $class = ref $obj;

    my $meta = Coat::Meta->has( $class, $attr );

    my $default = $meta->{'default'};
    return undef unless defined $default;

    return (ref $default)
        ? $default->($obj)  # we have a CODE ref
        : $default;     # we have a plain scalar
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
    foreach my $parent (@{ Coat::Meta->parents( $class ) }) {
        my $parent_attr = Coat::Meta->has( $parent, $attribute );
        return $parent_attr if defined $parent_attr;
    }

    # none found, the attribute is not supported by the family 
    return undef;
}

# This will build the attributes for a class with all inherited attributes
sub all_attributes
{
    my ($self, $class, $hash) = @_;
    $hash = {} unless defined $hash;

    foreach my $parent (@{ Coat::Meta->family( $class ) }) {
        $hash = { %{ $hash }, %{ Coat::Meta->attributes( $parent ) } };
    }
    
    $hash = { %{ $hash }, %{ Coat::Meta->attributes( $class ) } };

    return $hash;
}

sub is_family 
{ 
    my ($self, $class, $parent) = @_;
    return grep /^$parent$/, @{$CLASSES->{'@!family'}{ $class }};
}


sub parents 
{ 
    my ($self, $class) = @_;
    { no strict 'refs'; return \@{"${class}::ISA"}; }
}

sub class_precedence_list {
    my ($self, $class) = @_;
    return if !$class;

    ( $class, map { $self->class_precedence_list($_) } @{$self->parents($class)} );
}

sub linearized_isa {
    my ($self, $class) = @_;
    my %seen;
    grep { !( $seen{$_}++ ) } $self->class_precedence_list($class);
}

sub is_parent 
{ 
    my ($self, $class, $parent) = @_;
    return grep /^$parent$/, @{ Coat::Meta->parents( $class ) };
}

sub family { 
    my ($self, $class) = @_;
    $CLASSES->{'@!family'}{ $class } ||= Coat::Meta->parents( $class );
}

sub add_to_family {
    my ($self, $class, $parent) = @_;
    
    # add the parent to the family if not already present
    if (not grep /^$parent$/, @{$CLASSES->{'@!family'}{ $class }}) {
        push @{ $CLASSES->{'@!family'}{ $class } }, $parent; 
    }
}

sub extends($$$);
sub extends($$$)
{ 
    my ($self, $class, $parents) = @_;
    $parents = [$parents] unless ref $parents;

     # init the family with parents if not exists
     if (! defined $CLASSES->{'@!family'}{ $class } ) {
        $CLASSES->{'@!family'}{ $class } = [];
     }
    
    # loop on each parent, add it to family and do the same 
    # with recursion through its family
    foreach my $parent (@$parents) {
        foreach my $ancestor (@{ Coat::Meta->parents( $parent ) }) {
            Coat::Meta->extends($class, $ancestor);
        }
        # we do it at the end, so we respect the order of ancestry
        Coat::Meta->add_to_family($class, $parent);
    }
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
