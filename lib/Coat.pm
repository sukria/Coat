package Coat;

use strict;
use warnings;

use Carp;

use Exporter;
use base 'Exporter';
use vars qw(@EXPORT $VERSION);

# The current version of this library
$VERSION = '0.1_0.2';

# our exported keywords for class description
@EXPORT = qw(var extends before after around);

##############################################################################
# Static declarations  (scope of the class)
##############################################################################

# This is the class placeholder for attribute descriptions
# it's present in scope of the class itself, not for each instance
my $CLASS_ATTRS = {};

# local accessors for class attributes/descriptions

# declare/get a class description
sub class { $CLASS_ATTRS->{$_[0]} ||= {} }

# set/get an attribute of a class
sub class_attr { @_ == 3 ? 
    $CLASS_ATTRS->{$_[0]}{$_[1]} = $_[2] : 
    $CLASS_ATTRS->{$_[0]}{$_[1]} ||= {}}

sub class_exists     { exists $CLASS_ATTRS->{$_[0]}            } 
sub class_has_attr   { exists $CLASS_ATTRS->{$_[0]}{$_[1]}     }
sub class_set_father { $CLASS_ATTRS->{__father}{$_[0]} = $_[1] }
sub class_get_father { $CLASS_ATTRS->{__father}{$_[0]}         }

# hooks for a module
sub hooks        { $CLASS_ATTRS->{__hooks}{ $_[0] } }
sub hooks_before { $CLASS_ATTRS->{__hooks}{ $_[0] }{before}{ $_[1] } ||= [] }
sub hooks_after  { $CLASS_ATTRS->{__hooks}{ $_[0] }{after}{ $_[1] } ||= [] }
sub hooks_around { $CLASS_ATTRS->{__hooks}{ $_[0] }{around}{ $_[1] } ||= [] }

# helper for copying a class description (used when inheriting from a class)
sub __copy_class_description($$) {
    my ( $source, $dest ) = @_;
    foreach my $key ( keys %{ $CLASS_ATTRS->{$source} } ) {
        $CLASS_ATTRS->{$dest}{$key} = $CLASS_ATTRS->{$source}{$key};
    }
}

# var() declares an attribute and builds the corresponding accessors
sub var {
    my ( $name, %options ) = @_;
    my $scope = __getscope();
    my $accessor = "${scope}::${name}";

    class_attr( $scope, $name, { type => 'Scalar', %options } );
    
    no strict 'refs';
    undef *${accessor} if defined *{accessor};
    *${accessor} = sub {
        my ($self, $value) = @_;
        croak "Unknown attribute '$name' for class ".ref($self) unless 
            $self->has($name);
        
        # want a set()
        if (@_ > 1) { 
            # for performance reasons, we don't use $self->set_value here
            my $attrs = $self->attrs;
            my $type  = $attrs->{$name}{type};

            # FIXME : this will be better when we have Coat::Types implemented
            croak "$type '$name' cannot be set to '$value'" unless 
                ( __value_is_valid( $value, $type ) );

            $self->{_values}{$name} = $value;
            return $value;
        }
        # want a get()
        else {
            return  $self->{_values}{$name};
        }
    };
}

# this is where inheritance takes place
sub extends {
    my ($father) = @_;
    croak "Cannot extend without a class name"
      unless defined $father;

    croak "Class '$father' is unknown, cannot extends"
      unless class_exists($father);

    my $class = __getscope();

    # first we inherit the class description from our father
    __copy_class_description( $father, $class );

    # then we tell Perl we actually inherits from our father
    eval "push \@${class}::ISA, '$father'";

    # save the fact that $class inherits from $father
    class_set_father( $class, $father ); 
}

# returns the parent class of the class given
sub super {
    my ($class) = @_;
    $class = __getscope() unless defined $class;
    return class_get_father( $class );
}

# local helpers for building wrapped methods
sub __hooks_before_push { push @{ hooks_before( $_[0], $_[1] ) }, $_[2] }
sub __hooks_after_push { push @{ hooks_after( $_[0], $_[1] ) }, $_[2] }
sub __hooks_around_push { push @{ hooks_around( $_[0], $_[1] ) }, $_[2] }
sub __build_sub_with_hook($$) 
{
    my ( $class, $method ) = @_;

    my $super        = super($class);
    my $super_method = "${super}::${method}";

    my $full_method = "${class}::${method}";
    no strict 'refs';
    undef *${full_method};

    my ( $before, $after, $around ) = (
        hooks_before( $class, $method ),
        hooks_after( $class, $method ),
        hooks_around( $class, $method )
    );

    *${full_method} = sub {
        my ( $self, @args ) = @_;
        my @result;
        my $result;

        if (@$before) {
            $_->(@_) for @$before;
        }

        if (@$around) {
            my $orig = \&$super_method;
            foreach my $hook (@$around) {
                if (wantarray) {
                    @result = $hook->( $orig, $self, @args );
                }
                else {
                    $result = $hook->( $orig, $self, @args );
                }
                $orig = $hook;
            }
        }
        else {
            if (wantarray) {
                @result = &$super_method( $self, @args );
            }
            else {
                $result = &$super_method( $self, @args );
            }
        }

        if (@$after) {
            if (wantarray) {
                @result = $_->( $self, @result, @args ) for @$after;
            }
            else {
                $result = $_->( $self, $result, @args ) for @$after;
            }
        }

        wantarray
          ? return @result
          : return $result;
    };
}

# the before hook catches the call to an inherited method and exectue
# the code given before the inherited method is called.
sub before {
    my ( $method, $code ) = @_;
    my $class = __getscope();
    __hooks_before_push( $class, $method, $code );
    __build_sub_with_hook( $class, $method );
}

# the after hook catches the call to an inherited method and executes
# the code after the inherited method is called
sub after {
    my ( $method, $code ) = @_;
    my $class = __getscope();
    __hooks_after_push( $class, $method, $code );
    __build_sub_with_hook( $class, $method );
}

# the around hook catches the call to an inherited method and lets you do
# whatever you want with it, you get the coderef of the parent method and the
# args, you play !
sub around {
    my ( $method, $code ) = @_;
    my $class = __getscope();
    __hooks_around_push( $class, $method, $code );
    __build_sub_with_hook( $class, $method );
}

##############################################################################
# Public instance methods
##############################################################################

# returns the attributes descriptions for the class of that instance
sub attrs {
    my ($self) = @_;
    return class( __getscope($self) );
}

# tells if the given attribute is delcared for the class of that instance
sub has {
    my ( $self, $var ) = @_;
    return class_has_attr( __getscope($self), $var );
}

# init an instance : put default values and set values
# given at instanciation time
sub init {
    my ( $self, %attrs ) = @_;

    # default values
    my $class_attr = $self->attrs;
    foreach my $attr ( keys %{$class_attr} ) {
        if ( defined $class_attr->{$attr}{default} ) {
            $self->set_value( $attr, $class_attr->{$attr}{default} );
        }
    }

    # forced values
    foreach my $attr ( keys %attrs ) {
        $self->set_value( $attr, $attrs{$attr} );
    }
}

# The default constructor
sub new {
    my ( $class, %args ) = @_;

    my $self = {};
    bless $self, $class;

    $self->init(%args);

    return $self;
}

sub set_value
{
    my ($self, $name, $value) = @_;
    my $attrs = $self->attrs;
    my $type  = $attrs->{$name}{type};
    
    # FIXME : this will be better when we have Coat::Types implemented
    croak "$type '$name' cannot be set to '$value'" unless 
        ( __value_is_valid( $value, $type ) );

    $self->{_values}{$name} = $value;
    return $value;
}

# accessors for the instance attributes : get
sub get_value {
    my ( $self, $attr ) = @_;
    unless ( $self->has($attr) ) {
        croak "Unknown attribute '$attr' for class "
          . ref($self)
          . ", cannot get";
    }
    return $self->{_values}{$attr};
}

##############################################################################
# Private methods
##############################################################################

# The scope is used for saving attribute properties, we want to have
# one namespace per class that inherits from us
sub __getscope {
    my ($self) = @_;

    if ( defined $self ) {
        return ref($self);
    }
    else {
        return ( scalar( caller(1) ) );
    }
}

# check the attributes integrity
sub __value_is_valid($$) {
    my ( $value, $type ) = @_;
    return 1 if $type eq 'Scalar';

    my $lexical_rules = {
        Int     => '^\d+$',
        String  => '\w*',
        Boolean => '^[01]$',
    };

    if ( defined $lexical_rules->{$type} ) {
        my $pattern = $lexical_rules->{$type};
        return $value =~ /$pattern/;
    }

    # refs
    elsif ( $type eq 'ArrayRef' ) {
        return ref($value) eq 'ARRAY';
    }

    elsif ( $type eq 'HashRef' ) {
        return ref($value) eq 'HASH';
    }

    elsif ( $type eq 'CodeRef' ) {
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

    # import strict and warnings
    strict->import;
    warnings->import;
    
    # delcare the class
    class(__getscope());
    
    # forced inheritance to caller
    eval "push \@${caller}::ISA, 'Coat'";
    croak "Unable to inherit from Coat : $@" if $@;

    return if $caller eq 'main';
    Coat->export_to_level( 1, @_ );
}

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

=head2 extends

The keyword "extends" allows you to declare that a class "foo" inherits from a
class "bar". All attributes properties of class "bar" will be applied to class
"foo" as well as the accessors of class "bar".

Here is an example with Point3D, an extension of Point previously declared in
this documentation:

  package Point3D;

  use Coat;
  extends 'Point';

  var 'z' => (type => 'Int', default => 0):

  my $point3d = new Point3D x => 1, y => 3, z => 1;
  $point3d->x;    # will return: 1
  $point3d->y;    # will return: 3
  $point3d->z;    # will return: 1

=head1 HOOKS

Like Moose, Coat lets you define hooks. There are three kind of hooks :
before, after and around.

=head2 before

When writing a "before" hook you can catch the call to an inherited method,
and execute some code before the inherited method is called.

Example:

  package Foo;
  use Coat;

  sub method { return 4; }

  package Bar;
  use Coat;
  extends 'Foo';

  around 'method' => sub {
    my ($self, @args) = @_;
    # ... here some stuff to do before Foo::method is called
  };


=head2 after

When writing an "after" hook you can catch the call to an inherited method and 
execute xome code after the original method is executed. You receive in your
hook the result of the father's method.

Example:

  package Foo;
  use Coat;

  sub method { return 4; }

  package Bar;
  use Coat;
  extends 'Foo';

  after 'method' => sub {
    my ($self, $result, @args) = @_;
    return $result + 3;
  };

=head2 around

When writing an "around" hook you can catch the call to an inherited method and 
actually redefine it on-the-fly.
You get the code reference to the parent's method and its arguments, and can
do what you want then. It's a very powerful hook but also dangerous, so be
careful when writing such a hook not to break the original call.

Example:

  package Foo;
  use Coat;

  sub method { return 4; }

  package Bar;
  use Coat;
  extends 'Foo';

  # the following around hook implement the previous 'after' hook 
  # defined in this documentaiton.

  around 'method' => sub {
    my $orig = shift;
    my ($self, @args) = @_;

    my $res = $self->$orig(@args);
    return $res + 3;
  }

=head1 AUTHOR

Coat was written by Alexis Sukrieh <sukria+perl@sukria.net>

=head1 COPYING

Coat is copyright (c) 2007 Alexis Sukrieh.

L<http://www.sukria.net/perl/coat/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

