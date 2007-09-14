package Coat;

use strict;
use warnings;

use Carp;

use Exporter;
use base 'Exporter';
use vars qw(@EXPORT $VERSION);
@EXPORT  = qw(var);
$VERSION = '0.1';

##############################################################################
# Static declarations  (scope of the class)
##############################################################################

# This is the class placeholder for attribute descriptions
# it's present in scope of the class itself, not for each instance
my $CLASS_ATTRS = {};

# public class methods

# the var method is exported, it allows us to delcare attributes
# for the class
# default type is "scalar"
sub var {
    my ($name, %options) = @_;
    my $scope = __getscope();
    $CLASS_ATTRS->{$scope}{$name} = { type => 'Scalar', %options };
}

##############################################################################
# Public instance methods
##############################################################################

# returns the attributes descriptions for the class of that instance
sub attrs {
    my ($self) = @_;
    return $CLASS_ATTRS->{ __getscope($self) };
}

# tells if the given attribute is delcared for the class of that instance
sub has {
    my ($self, $var) = @_;
    return exists $CLASS_ATTRS->{ __getscope($self) }{$var};
}

# init an instance : put default values and set values
# given at instanciation time
sub init {
    my ($self, %attrs) = @_;

    # default values
    my $class_attr = $self->attrs;
    foreach my $attr (keys %{$class_attr}) {
        if (defined $class_attr->{$attr}{default}) {
            $self->set($attr, $class_attr->{$attr}{default});
        }
    }

    # forced values
    foreach my $attr (keys %attrs) {
        $self->set($attr, $attrs{$attr});
    }
}

# The default constructor
sub new {
    my ($class, %args) = @_;

    my $self = {};
    bless $self, $class;

    $self->init(%args);

    return $self;
}

# accessors for the instance attributes : set
sub set {
    my ($self, $attr, $value) = @_;
    unless ($self->has($attr)) {
        croak "Unknown attribute '$attr' for class "
          . ref($self)
          . ", cannot set";
    }

    # check the attribute's value match its type
    my $attrs = $self->attrs;
    my $type  = $attrs->{$attr}{type};
    unless (__value_is_valid($value, $type)) {
        croak "$type '$attr' cannot be set to '$value'";
    }

    $self->{_values}{$attr} = $value;
    return $value;
}

# accessors for the instance attributes : get
sub get {
    my ($self, $attr) = @_;
    unless ($self->has($attr)) {
        croak "Unknown attribute '$attr' for class "
          . ref($self)
          . ", cannot get";
    }
    return $self->{_values}{$attr};
}

# some AUTOLOAD magic to build dynamic accessors for each attribute
sub AUTOLOAD {
    my ($self, @args) = @_;

    our $AUTOLOAD;
    my @tokens = split('::', $AUTOLOAD);
    my $method = $tokens[$#tokens];
    return 1 if $method eq 'DESTROY';

    # do we ask for an accessor?
    if ($self->has($method)) {
        my ($value) = @args;
        if (defined $value) {
            return $self->set($method, $value);
        }
        else {
            return $self->get($method);
        }
    }

    else {
        croak "unknown method '$method' for class '" . ref($self) . "'";
    }

}

##############################################################################
# Private methods
##############################################################################

# The scope is used for saving attribute properties, we want to have
# one namespace per class that inherits from us
sub __getscope {
    my ($self) = @_;

    if (defined $self) {
        return ref($self);
    }
    else {
        return (scalar(caller(1)));
    }
}

# check the attributes integrity
sub __value_is_valid($$) {
    my ($value, $type) = @_;
    return 1 if $type eq 'Scalar';

    my $lexical_rules = {
        Int     => '^\d+$',
        String  => '\w*',
        Boolean => '^[01]$',
    };

    if (defined $lexical_rules->{$type}) {
        my $pattern = $lexical_rules->{$type};
        return $value =~ /$pattern/;
    }

    # refs
    elsif ($type eq 'ArrayRef') {
        return ref($value) eq 'ARRAY';
    }

    elsif ($type eq 'HashRef') {
        return ref($value) eq 'HASH';
    }

    elsif ($type eq 'CodeRef') {
        return ref($value) eq 'CODE';
    }

    # take the type as a classname
    else {
        return ref($value) eq $type;
    }
}

##############################################################################
# Loading time cooking
##############################################################################

# we override the import method to actually force the "strict" and "warnings"
# modes to children.
sub import {
    my $caller = caller;

    strict->import;
    warnings->import;

    return if $caller eq 'main';
    Coat->export_to_level(1, @_);
}

# We force the caller to inherit from us
{
    my $caller = caller();
    eval "\@${caller}::ISA = qw(Coat)";
};

1;
__END__

=pod

=head1 NAME

Coat -- a meta class for building light objects with accessors

=head1 DESCRIPTION

This module was inspired by the excellent Moose meta class which provides
enhanced object creation for Perl 5.

Moose is great, but slow and has huge dependencies which makes it difficult to
use in restricted environments.

This module implements the basic goodness of Moose, namely the accessor
automagic. 

B<It is not Moose>

It is designed for developers who want to write clean object code with Perl 5
without depending on Moose. This implies you don't rely on all the features of
Moose; and you don't depend on a huge set of dependencies, all you have to
install is Coat (which is independant, no need of external modules).

=head1 SYNTAX

    package Point;
    use Coat;  # once the use is done, the class already 
               # inherits from it

    var 'x' => (type => 'Int', default => 0);
    var 'y' => (type => 'Int', default => 0);

    1;

    my $point = new Point x => 2, y => 4;
    $point->x;    # returns 2
    $point->y;    # returns 4
    $point->x(9); # returns 9

Note that we don't need to import "strict" and "warnings" modules as
Coat propagates them to our class (use strict and use warnings are
implicit in our class).

=head1 STATIC METHODS

=head2 var 'name' => %options

The static method B<var> allows you to define attributes for your class.
Attributes declared this way will be available in the objects
(accessors will let you get and set it).

This static method is similar to Moose's B<has> method.

You can handle each attribute options with the %options hashtable. The
following options are supported:

=head3 type

The attribute's type, put here either a class name or one of the 
supported type: 

=over 4

=item Int

=item String

=item Boolean

=back


=head3 default

The attribute's default value (the attribute will have this
value at instanciation time if none given).

=back

=head1 AUTHOR

Coat was written by Alexis Sukrieh <sukria+perl@sukria.net>

=head1 COPYING

Coat is copyright (c) 2007 Alexis Sukrieh.

L<http://www.sukria.net/perl/coat/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

