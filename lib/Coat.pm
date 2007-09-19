package Coat;

use strict;
use warnings;
use Carp 'confess';
use Symbol;

use Exporter;
use base 'Exporter';
use vars qw(@EXPORT $VERSION $AUTHORITY);

# This is the mother class for each class that uses Coat
use Coat::Object;

$VERSION   = '0.1_0.3';
$AUTHORITY = 'cpan:SUKRIA';

# our exported keywords for class description
@EXPORT = qw(has extends before after around);

# This is the class placeholder for attribute descriptions
# it's present in scope of the class itself, not for each instance
my $CLASS_ATTRS = {};

# local accessors for class attributes/descriptions

# declare/get a class description
sub class { $CLASS_ATTRS->{ $_[0] } ||= {} }

# set/get an attribute of a class
sub class_attr {
    @_ == 3
      ? $CLASS_ATTRS->{ $_[0] }{ $_[1] } = $_[2]
      : $CLASS_ATTRS->{ $_[0] }{ $_[1] } ||= {};
}

sub class_exists     { exists $CLASS_ATTRS->{ $_[0] } }
sub class_has_attr   { exists $CLASS_ATTRS->{ $_[0] }{ $_[1] } }
sub class_set_mother { $CLASS_ATTRS->{__mother}{ $_[0] } = $_[1] }
sub class_get_mother { $CLASS_ATTRS->{__mother}{ $_[0] } }

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

# has() declares an attribute and builds the corresponding accessors
sub has {
    my ( $name, %options ) = @_;
    confess "Attribute is a reference, cannot declare" if ref($name);

    my $scope    = getscope();
    my $accessor = "${scope}::${name}";

    class_attr( $scope, $name, { type => 'Scalar', %options } );

    my $accessor_code = sub {
        my ( $self, $value ) = @_;
        confess "Unknown attribute '$name' for class " . ref($self)
          unless $self->has_attr($name);

        # want a set()
        if ( @_ > 1 ) {
            my $attrs = $self->meta;
            my $type  = $attrs->{$name}{type};

            # FIXME : this will be better when we have Coat::Types implemented
            confess "$type '$name' cannot be set to '$value'"
              unless ( __value_is_valid( $value, $type ) );

            $self->{_values}{$name} = $value;
            return $value;
        }

        # want a get()
        else {
            return $self->{_values}{$name};
        }
    };

    # now bind the subref to the appropriate symbol in the caller class
    __bind_coderef_to_symbol( $accessor_code, $accessor );
}

# the private method for declaring inheritance, we can here overide the
# caller class with a random one, useful for our internal cooking, see import().
sub __extends_class {
    my ( $mothers, $class ) = @_;
    $class = getscope() unless defined $class;

    # the extends mechanism overwrite the @ISA list
    { no strict 'refs'; @{"${class}::ISA"} = (); }

    # then we inherit from all the mothers given
    foreach my $mother (@$mothers) {
        confess "Class '$mother' is unknown, cannot extends"
          unless class_exists($mother);

        # first we inherit the class description from our mother
        __copy_class_description( $mother, $class );

        # add the mother to our ancestors
        { no strict 'refs'; push @{"${class}::ISA"}, $mother; }

        # save the fact that $class inherits from $mother
        class_set_mother( $class, $mother );
    }
}

# the public inheritance method, takes a list of class we should inherit from
sub extends {
    my (@mothers) = @_;
    confess "Cannot extend without a class name"
      unless @mothers;
    __extends_class( \@mothers, getscope() );
}

# returns the parent class of the class given
sub super {
    my ($class) = @_;
    $class = getscope() unless defined $class;
    return class_get_mother($class);
}

# local helpers for building wrapped methods
sub __hooks_before_push { push @{ hooks_before( $_[0], $_[1] ) }, $_[2] }
sub __hooks_after_push { push @{ hooks_after( $_[0], $_[1] ) }, $_[2] }
sub __hooks_around_push { push @{ hooks_around( $_[0], $_[1] ) }, $_[2] }

# The idea here is to loop on each coderef given
# and build subs to ensure the orig coderef is correctly propagated.
# -> We rewrite the "around" hooks defined to pass their coderef neighboor as
# a first argument.
# (big thank to STEVAN's Class::MOP here, which was helpful with the idea of
# $compile_around_method)
sub __compile_around_modifier {
    {
        my $orig = shift;
        return $orig unless @_;

        my $hook = shift;
        @_ = ( sub { $hook->( $orig, @_ ) }, @_ );
        redo;
    }
}

# This one is the wrapper builder for method with hooks.
# It can mix up before, after and around hooks.
sub __build_sub_with_hook($$) {
    my ( $class, $method ) = @_;

    my $super        = super($class);
    my $full_method  = "${class}::${method}";
    my $super_method = *{ qualify_to_ref( $method => $super ) };

    my ( $before, $after, $around ) = (
        hooks_before( $class, $method ),
        hooks_after( $class, $method ),
        hooks_around( $class, $method )
    );

    my $modified_method_code = sub {
        my ( $self, @args ) = @_;
        my @result;
        my $result;

        $_->(@_) for @$before;

        my $around_modifier =
          __compile_around_modifier( \&$super_method, @$around );

        ( defined wantarray )
          ? (
            wantarray
            ? ( @result = $around_modifier->(@_) )
            : ( $result = $around_modifier->(@_) )
          )
          : ( $around_modifier->(@_) );

        $_->(@_) for @$after;

        return unless defined wantarray;
        return wantarray ? @result : $result;
    };

    # now bind the new method to the appropriate symbol
    __bind_coderef_to_symbol( $modified_method_code, $full_method );
}

# the before hook catches the call to an inherited method and exectue
# the code given before the inherited method is called.
sub before {
    my ( $method, $code ) = @_;
    my $class = getscope();
    __hooks_before_push( $class, $method, $code );
    __build_sub_with_hook( $class, $method );
}

# the after hook catches the call to an inherited method and executes
# the code after the inherited method is called
sub after {
    my ( $method, $code ) = @_;
    my $class = getscope();
    __hooks_after_push( $class, $method, $code );
    __build_sub_with_hook( $class, $method );
}

# the around hook catches the call to an inherited method and lets you do
# whatever you want with it, you get the coderef of the parent method and the
# args, you play !
sub around {
    my ( $method, $code ) = @_;
    my $class = getscope();
    __hooks_around_push( $class, $method, $code );
    __build_sub_with_hook( $class, $method );
}

# we override the import method to actually force the "strict" and "warnings"
# modes to children and also to force the Coat::Object inheritance.
sub import {
    my $caller = caller;

    # import strict and warnings
    strict->import;
    warnings->import;

    # delcare the class
    class( getscope() );

    # be sure Coat::Object is known as a valid class
    class('Coat::Object');

    # force inheritance from Coat::Object
    __extends_class( ['Coat::Object'], getscope() );

    return if $caller eq 'main';
    Coat->export_to_level( 1, @_ );
}

##############################################################################
# Protected methods (only called from Coat::* friends)
##############################################################################

# The scope is used for saving attribute properties, we want to have
# one namespace per class that inherits from us
sub getscope {
    my ($self) = @_;

    if ( defined $self ) {
        return ref($self);
    }
    else {
        return ( scalar( caller(1) ) );
    }
}

##############################################################################
# Private methods (only called from Coat.pm)
##############################################################################

sub __bind_coderef_to_symbol($$) {
    my ( $coderef, $symbol ) = @_;
    {
        no strict 'refs';
        no warnings 'redefine', 'prototype';
        *$symbol = $coderef;
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

1;
__END__

=pod

=head1 NAME

Coat -- A light and self-dependant meta-class for Perl5

=head1 DESCRIPTION

This module was inspired by the excellent C<Moose> meta class which provides
enhanced object creation for Perl5.

Moose is great, but has huge dependencies which makes it difficult to
use in restricted environments.

This module implements the basic goodness of Moose, namely accessors
automagic, hook modifiers and inheritance facilities. 

B<It is not Moose> but the small bunch of features provided are
B<Moose-compatible>. That means you can start with Coat and, if later you
get to the point where you can or want to upgrade to Moose, your code won't
have to change : every features provided by Coat exist in the Moose's API (but
the opposite is not true, as you can imagine).

=head1 SYNTAX

When you define a class with C<Coat> (eg: use Coat;), you declare a class that
inherits from the main C<Coat> mother-class: C<Coat::Object>. C<Coat> is the
meta-class, C<Coat::Object> is the mother-class. 

The meta-class will help you define the class itself (inheritance, attributes,
method modifiers) and the mother-class will provide to your class a set of
default instance-methods such as a constructor and default accessors for your
attributes.

Here is a basic example with a class "Point": 

    package Point;
    use Coat;  # once the use is done, the class already 
               # inherits from Coat::Object, the mother-class.

    # describe attributes...
    has 'x' => (type => 'Int', default => 0);
    has 'y' => (type => 'Int', default => 0);

    # and your done
    1;

    my $point = new Point x => 2, y => 4;
    $point->x;    # returns 2
    $point->y;    # returns 4
    $point->x(9); # returns 9

Note that there's no need to import the "strict" and "warnings" modules, it's
already exported by Coat when you use it.

=head1 STATIC METHODS

Coat provides you with static methods you use to define your class.
They're respectingly dedicated to set inheritance, declare attributes
and define method modifiers (hooks).

=head2 INHERITANCE

The keyword "extends" allows you to declare that a class "Child" inherits from a
class "Parent". All attributes properties of class "Parent" will be applied to class
"Child" as well as the accessors of class "Parent".

Here is an example with Point3D, an extension of Point previously declared in
this documentation:

  package Point3D;

  use Coat;
  extends 'Point';

  has 'z' => (type => 'Int', default => 0):

  my $point3d = new Point3D x => 1, y => 3, z => 1;
  $point3d->x;    # will return: 1
  $point3d->y;    # will return: 3
  $point3d->z;    # will return: 1

=head2 ATTRIBUTES AND ACCESSORS

The static method B<has> allows you to define attributes for your class.

You can handle each attribute options with the %options hashtable. The
following options are supported:

=head3 type

More to come later here...

=head3 default

The attribute's default value (the attribute will have this
value at instanciation time if none given).

=head1 METHOD MODIFIERS (HOOKS)

Like C<Moose>, Coat lets you define hooks. There are three kind of hooks :
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
execute some code after the original method is executed. You receive in your
hook the result of the mother's method.

Example:

  package Foo;
  use Coat;

  sub method { return 4; }

  package Bar;
  use Coat;
  extends 'Foo';

  my $flag;

  after 'method' => sub {
    my ($self, @args) = @_;
    $flag = 1;
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

  around 'method' => sub {
    my $orig = shift;
    my ($self, @args) = @_;

    my $res = $self->$orig(@args);
    return $res + 3;
  }

=head1 SEE ALSO

C<Moose> is the mother of Coat, every concept inside Coat was friendly stolen
from it, you definitely want to look at C<Moose>.

=head1 AUTHORS

This module was written by Alexis Sukrieh E<lt>sukria+perl@sukria.netE<gt>

Strong and helpful reviews were made by Stevan Little and 
Matt (mst) Trout ; this module wouldn't be there without their help.
Huge thank to them.

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Alexis Sukrieh.

L<http://www.sukria.net/perl/coat/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
