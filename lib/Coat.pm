package Coat;

use strict;
use warnings;
use Carp 'confess';
use Symbol;
use B 'svref_2object';

use Exporter;
use base 'Exporter';
use vars qw(@EXPORT $VERSION $AUTHORITY);

use Coat::Meta;
use Coat::Object;
use Coat::Types;

$VERSION   = '0.334';
$AUTHORITY = 'cpan:SUKRIA';

# our exported keywords for class description
@EXPORT = qw(has extends before after around);

# Prototypes for private methods
sub _bind_coderef_to_symbol($$);
sub _extends_class($;$);
sub _value_is_valid($$);
sub _compile_around_modifier(@);
sub _build_sub_with_hook($$);

##############################################################################
# Public static methods
##############################################################################

# has() declares an attribute and builds the corresponding accessors
sub has {
    my ( $attr_name, %options ) = @_;
    confess "Attribute is a reference, cannot declare" if ref($attr_name);

    my $class    = $options{'!caller'} || getscope();
    my $accessor = "${class}::${attr_name}";

    # handle here attr overloading (eg: has '+foo' overload SUPER::foo)
    if ($attr_name =~ /^\+(\S+)$/) {
        $attr_name = $1;
        
        my $inherited_attrs = Coat::Meta->all_attributes( $class );
        (exists $inherited_attrs->{$attr_name}) ||
            confess "Cannot overload unknown attribute ($attr_name)";
        
        %options = (%{$inherited_attrs->{$attr_name}}, %options );
    }

    my $attr_meta = Coat::Meta->attribute( $class, $attr_name, \%options);
    my $accessor_code = _accessor_for_attr($attr_name);

    # now bind the subref to the appropriate symbol in the caller class
    _bind_coderef_to_symbol( $accessor_code, $accessor );

    my $handles = $attr_meta->{'handles'};
    if ($handles && ref $handles eq 'HASH') {

        foreach my $method ( keys %{$handles} ) {
            my $handler = "${class}::${method}";
            my $handle = $handles->{$method};
            my $handles_code = sub {
                my ( $self, @args ) = @_;

                if ( $self->$attr_name->can( $handle ) ) {
                    return $self->$attr_name->$handle( @args );
                }
                else {
                    confess( 'Cannot call ' . $handle . ' from ' . $attr_name );
                }
            };
            _bind_coderef_to_symbol( $handles_code, $handler );
        }
    }

    my $predicate = $attr_meta->{'predicate'};
    if ($predicate) {
        my $full = "${class}::$predicate";
        my $predicate_code = sub { exists $_[0]->{$attr_name} };
        _bind_coderef_to_symbol( $predicate_code => $full );
    }

    my $clearer = $attr_meta->{'clearer'};
    if ($clearer) {
        my $full = "${class}::$clearer";
        my $clearer_code = sub { delete $_[0]->{$attr_name} };
        _bind_coderef_to_symbol( $clearer_code => $full );
    }
}

# the public inheritance method, takes a list of class we should inherit from
sub extends {
    my (@mothers) = @_;
    confess "Cannot extend without a class name"
      unless @mothers;
    _extends_class( \@mothers, getscope() );
}

# the before hook catches the call to an inherited method and exectue
# the code given before the inherited method is called.
sub before {
    my ( $method, $code ) = @_;
    my $class = getscope();
    Coat::Meta->before_modifiers( $class, $method, $code );
    _build_sub_with_hook( $class, $method );
}

# the after hook catches the call to an inherited method and executes
# the code after the inherited method is called
sub after {
    my ( $method, $code ) = @_;
    my $class = getscope();
    Coat::Meta->after_modifiers( $class, $method, $code );
    _build_sub_with_hook( $class, $method );
}

# the around hook catches the call to an inherited method and lets you do
# whatever you want with it, you get the coderef of the parent method and the
# args, you play !
sub around {
    my ( $method, $code ) = @_;
    my $class = getscope();
    Coat::Meta->around_modifiers( $class, $method, $code );
    _build_sub_with_hook( $class, $method );
}

# we override the import method to actually force the "strict" and "warnings"
# modes to children and also to force the Coat::Object inheritance.
sub import {
    my $caller = caller;
    return if $caller eq 'main';
    my $class_name = getscope();

    # import strict and warnings
    strict->import;
    warnings->import;

    # delcare the class
    Coat::Meta->class( $class_name );

    # be sure Coat::Object is known as a valid class
    Coat::Meta->class('Coat::Object');

    # the class *cannot* be named like a built-in type!
    (grep /^$class_name$/, Coat::Types::list_all_builtin_type_constraints) &&
        confess "Class cannot be named like a built-in type constraint ($class_name)";

    # register the class as a valid type
    Coat::Types::find_or_create_type_constraint( $class_name );

    # force inheritance from Coat::Object
    _extends_class( ['Coat::Object'], $class_name );

    Coat->export_to_level( 1, @_ );
}

# clean the namespace when the module is unloaded (no Coat).
# This is mostly stolen from Moose.
sub unimport {
    no strict 'refs';
    my $class = caller();

    # loop through the exports ...
    foreach my $name ( @EXPORT ) {

        # if we find one ...
        if ( defined &{ $class . '::' . $name } ) {
            my $keyword = \&{ $class . '::' . $name };

            # make sure it is from Coat
            my $pkg_name =
                eval { svref_2object($keyword)->GV->STASH->NAME };
            next if $@;
            next if $pkg_name ne 'Coat';

            # and if it is from Coat then undef the slot
            delete ${ $class . '::' }{$name};
        }
    }
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
        return scalar caller 1;
    }
}

##############################################################################
# Private methods
##############################################################################


# TODO : Should find a way to build optimized non-mutable accessors here
# It's ugly to get and check the meta of the attribute whenver using the setter or the
# getter.
sub _accessor_for_attr {
    my ($name) = @_;

    return sub {
        my ( $self, $value ) = @_;
        my $meta = Coat::Meta->has( ref($self), $name );

        # setter
        if ( @_ > 1 ) {
            confess "Cannot set a read-only attribute ($name)" 
                if ($meta->{'is'} eq 'ro');

            $value = Coat::Types->validate( $meta, $name, $value );
            $self->{$name} = $value;

            $meta->{'trigger'}->($self, $value) 
                if defined $meta->{'trigger'};
            
            return $value;
        }

        # getter
        else {
            $self->{$name} = Coat::Meta->attr_default( $self, $name)
                if ($meta->{lazy} && !defined($self->{$name}));
                
            return $self->{$name};
        }
    };
}

# The idea here is to loop on each coderef given
# and build subs to ensure the orig coderef is correctly propagated.
# -> We rewrite the "around" hooks defined to pass their coderef neighboor as
# a first argument.
# (big thank to STEVAN's Class::MOP here, which was helpful with the idea of
# $compile_around_method)
sub _compile_around_modifier(@) {
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
sub _build_sub_with_hook($$) {
    my ( $class, $method ) = @_;

    my $parents = Coat::Meta->family( $class );
    my $super   = undef;

    # we have to find where in the inheritance tree $super is providing
    # $method
    foreach my $parent_class (@$parents) {
        # looking for the first inherited method
        my $coderef;
        { 
            no strict 'refs'; 
            $coderef = *{ "${parent_class}::${method}" };
        }
        $super = $parent_class if defined &$coderef;
    }

    # $method not found, something is wrong there
    confess "Unable to find method \"$method\" in inherited classes"
        unless defined $super;

    my $full_method  = "${class}::${method}";
    my $super_method = *{ qualify_to_ref( $method => $super ) };

    my ( $before, $after, $around ) = (
        Coat::Meta->before_modifiers( $class, $method ),
        Coat::Meta->after_modifiers ( $class, $method ),
        Coat::Meta->around_modifiers( $class, $method ),
    );

    my $modified_method_code = sub {
        my ( $self, @args ) = @_;
        my @result;
        my $result;

        $_->(@_) for @$before;

        my $around_modifier =
          _compile_around_modifier( \&$super_method, @$around );

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
    _bind_coderef_to_symbol( $modified_method_code, $full_method );
}

# the private method for declaring inheritance, we can here overide the
# caller class with a random one, useful for our internal cooking, see import().
sub _extends_class($;$) {
    my ( $mothers, $class ) = @_;
    $class = getscope() unless defined $class;

    # then we inherit from all the mothers given, if they are valid
    foreach my $mother (@$mothers) {
        # class is unknown, never been loaded, let's try to import it
        unless ( Coat::Meta->exists($mother) ) {
            eval "use $mother";
            confess "Could not load class ($mother) because : $@" if $@;
            $mother->import;
        }
        Coat::Meta->extends( $class, $mother );
    }

    # Add all the mothers to our ancestors.
    # The extends mechanism overwrite the @ISA list.
    { no strict 'refs'; @{"${class}::ISA"} = @$mothers; }
}

sub _bind_coderef_to_symbol($$) {
    my ( $coderef, $symbol ) = @_;
    {
        no strict 'refs';
        no warnings 'redefine', 'prototype';
        *$symbol = $coderef;
    }
}



1;
__END__

=pod

=head1 NAME

Coat -- A light and self-dependent meta-class for Perl5

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
inherits from the main mother-class: L<Coat::Object>. 

The I<Coat> module itself exports all the symbols needed to build a class and 
L<Coat::Meta> provides access to the meta class informations (attribute descriptions,
inheritance data, etc).

Here is a basic example with a class "Point": 

    package Point;
    use Coat;  # once the use is done, the class already 
               # inherits from Coat::Object, the mother-class.

    # describe attributes...
    has 'x' => (isa => 'Int', default => 0);
    has 'y' => (isa => 'Int', default => 0);

    # and your done
    1;

    my $point = new Point x => 2, y => 4;
    $point->x;    # returns 2
    $point->y;    # returns 4
    $point->x(9); # returns 9

Note that there's no need to import the "strict" and "warnings" modules, it's
already exported by Coat when you use it.

=head1 METHODS

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

  has 'z' => (isa => 'Int', default => 0):

  my $point3d = new Point3D x => 1, y => 3, z => 1;
  $point3d->x;    # will return: 1
  $point3d->y;    # will return: 3
  $point3d->z;    # will return: 1

=head2 ATTRIBUTES AND ACCESSORS

The static method B<has> allows you to define attributes for your class; it
should be used like the following:

B<has $name =E<gt> %options>

This will install an attribute of a given C<$name> into the current class. 
The following options are supported:

=over 4

=item I<is =E<gt> 'rw'|'ro'>

The I<is> option accepts either I<rw> (for read/write) or I<ro> (for read 
only). These will create either a read/write accessor or a read-only 
accessor respectively, using the same name as the C<$name> of the attribute.

=item I<isa =E<gt> $type_name>

The I<isa> option uses Coat's type constraint facilities to set up runtime 
type checking for this attribute. Coat will perform the checks during class 
construction, and within any accessors. The C<$type_name> argument must be a 
string. The string may be either a class name or a type defined by
L<Coat::Types>.

=item I<required =E<gt> (1|0)>

This marks the attribute as being required. This means a I<defined> value must be 
supplied during class construction, and the attribute may never be set to 
C<undef> with an accessor. 

=item I<default>

Change the default value of an attribute.
Be aware that like with Moose, only plain scalars and code references are allowed 
when declaring a default value (wrap other references in subs).

=item I<trigger =E<gt> $code>

The I<trigger> option is a CODE reference which will be called after the value of
the attribute is set. The CODE ref will be passed the instance itself, the
updated value and the attribute meta-object (this is for more advanced fiddling
and can typically be ignored). You B<cannot> have a trigger on a read-only
attribute.


=head2 METHOD MODIFIERS (HOOKS)

Like C<Moose>, Coat lets you define hooks. There are three kind of hooks :
before, after and around.

=head3 before

When writing a "before" hook you can catch the call to an inherited method,
and execute some code before the inherited method is called.

Example:

  package Foo;
  use Coat;

  sub method { return 4; }

  package Bar;
  use Coat;
  extends 'Foo';

  before 'method' => sub {
    my ($self, @args) = @_;
    # ... here some stuff to do before Foo::method is called
  };


=head3 after

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

=head3 around

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

L<Moose> is the mother of Coat, every concept inside Coat was friendly stolen
from it, you definitely want to look at it.

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
