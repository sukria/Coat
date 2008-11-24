package Coat::Types;

use strict;
use warnings;

use Carp 'confess';
use base 'Exporter';
use vars qw(@EXPORT);

use Coat::Meta::TypeConstraint;

# Moose/Coat keywords
sub as      ($);
sub from    ($);
sub where   (&);
sub message (&);
sub type    ($$;$);
sub subtype ($$;$$);
sub enum    ($;@);
sub via     (&);
sub coerce  ($@);

@EXPORT = qw(
    type subtype enum coerce
    from as where via message
    
    register_type_constraint
    find_type_constraint
    find_or_create_type_constraint
    
    list_all_type_constraints
    list_all_builtin_type_constraints
    
    create_parameterized_type_constraint
    find_or_create_parameterized_type_constraint
);

sub as      ($) { $_[0] }
sub from    ($) { $_[0] }
sub where   (&) { $_[0] }
sub via     (&) { $_[0] }
sub message (&) { $_[0] }

# {{{ - Registry
# singleton for storing Coat::Meta::Typeconstrain objects

my $REGISTRY = { };

sub register_type_constraint {
    my ($tc) = @_;

    confess "can't register an unnamed type constraint"
        unless defined $tc->name;

    $REGISTRY->{$tc->name} = $tc;
}

sub find_type_constraint         { $REGISTRY->{$_[0]} }
sub list_all_type_constraints    { keys %$REGISTRY    }
sub get_type_constraint_registry { $REGISTRY          }

sub find_or_create_type_constraint {
    my ($type_name) = @_;
    
    my $tc = find_type_constraint( $type_name );
    return $tc if defined $tc;

    return register_type_constraint( Coat::Meta::TypeConstraint->new(
        name       => $type_name,
        parent     => 'Object',
        validation => sub { $_->isa($type_name) },
        message    => sub { "Value is not a member of class '$type_name' ($_)" },
    ));
}

# }}}

# {{{ - macro (type, subtype, coerce, enum)

sub type($$;$) { 
    my ($type_name, $validation_code, $message) = @_;
    
    register_type_constraint( new Coat::Meta::TypeConstraint(
        name       => $type_name,
        parent     => undef,
        validation => $validation_code,
        message    => $message) );
}

sub subtype ($$;$$) {
    my ($type_name, $parent, $validation_code, $message) = @_;

    register_type_constraint( new Coat::Meta::TypeConstraint(
        name       => $type_name,
        parent     => $parent,
        validation => $validation_code,
        message    => $message ) );
}

sub enum ($;@) {
    my ($type_name, @values) = @_;
    confess "You must have at least two values to enumerate through"
        unless (scalar @values >= 2);

    my $regexp = join( '|', @values );
	
    subtype $type_name 
        => as 'Str' 
        => where { /^$regexp$/i };    
}

sub coerce($@) {
    my ($type_name, %coercion_map) = @_;
    my $tc = find_or_create_type_constraint($type_name);

    if ($tc->has_coercion) {
        my $map = { %{ $tc->coercion_map }, %coercion_map };
        $tc->coercion_map ( $map );
    }
    else {
        $tc->coercion_map ( \%coercion_map );
    }
}

# }}}

# {{{ - exported functions 

sub export_type_constraints_as_functions {
    my $caller = caller;
    foreach my $t ( list_all_type_constraints() ) {
        my $constraint = find_type_constraint( $t );
        my $constraint_symbol = "${caller}::${t}";
        my $constraint_sub = sub {
            my ($value) = @_;
            local $_ = $value;
            return $constraint->validation->($value) ? 1 : undef;
        };
        {
            no strict 'refs';
            no warnings 'redefine', 'prototype';
            *$constraint_symbol = $constraint_sub;
        }
    }
}

sub validate {
    my ($class, $attr, $attribute, $value, $type_name) = @_;
    $type_name ||= $attr->{isa};

    # Exception if not defined and required attribute 
    confess "Attribute \($attribute\) is required and cannot be undef" 
        if ($attr->{required} && ! defined $value);

    # Bypass the type check if not defined and not required
    return $value if (! defined $value && ! $attr->{required});

    # get the current TypeConstraint object (or create it if not defined)
    my $tc = (_is_parameterized_type_constraint( $type_name ))
        ? find_or_create_parameterized_type_constraint( $type_name )
        : find_or_create_type_constraint( $type_name ) ;
    
    # look for coercion : if the constraint has coercion and
    # current value is of a supported coercion source type, coerce.
    if ($attr->{coerce}) {
        (not $tc->has_coercion) &&
            confess "Coercion is not available for type '".$tc->name."'";
        # coercing...
        $value = $tc->coerce($value);
    }

    # validate the value through the type-constraint
    $tc->validate( $value ); 

    return $value;
}

# }}}

# {{{ - parameterized type constraints 

sub find_or_create_parameterized_type_constraint ($) {
    my ($type_name) = @_;
    $REGISTRY->{$type_name} ||= create_parameterized_type_constraint( $type_name );
}

sub create_parameterized_type_constraint ($) {    
    my ($type_name) = @_;
    
    my ($base_type, $type_parameter) = 
        _parse_parameterized_type_constraint($type_name);
    
    (defined $base_type && defined $type_parameter)
        || confess "Could not parse type name ($type_name) correctly";

    my $tc_base = find_type_constraint( $base_type );
    (defined $tc_base)
        || confess "Could not locate the base type ($base_type)";
    
    confess "Unsupported base type ($base_type)" 
        if (! _base_type_is_arrayref($base_type) && 
            ! _base_type_is_hashref($base_type) );

    my $tc_param = find_type_constraint( $type_parameter );

    my $tc = Coat::Meta::TypeConstraint->new (
        name           => $type_name,
        parent         => $base_type,
        message        => sub { "Validation failed with value $_" });

    # now add parameterized type constraint validation code
    # depending on the base type
    if (_base_type_is_arrayref( $base_type )) {
        $tc->validation( sub { 
            foreach my $e (@$_) {
                eval { $tc_param->validate( $e )};
                return 0 if $@;
            }
            return 1;
        });
    }
    elsif (_base_type_is_hashref( $base_type )) {
        $tc->validation( sub {
            my $value = $_ || $_[0];

            foreach my $k (keys %$value) {
                eval { $tc_param->validate( $value->{$k} )};
                return 0 if $@;
            }
            return 1;
        });
    }

    # the type-constraint object is ready!
    return $tc;
}

# private subs for parameterized type constraints handling

sub _base_type_is_arrayref ($) {
    my ($type) = @_;
    return $type =~ /^ArrayRef|ARRAY$/;
}

sub _base_type_is_hashref ($) {
    my ($type) = @_;
    return $type =~ /^HashRef|HASH$/;
}

sub _parse_parameterized_type_constraint ($) {
    my ($type_name) = @_;

    if ($type_name =~ /^(\w+)\[([\w:_\d]+)\]$/) {
        return ($1, $2);
    }
    else { 
        return (undef, undef);
    }
}

sub _is_parameterized_type_constraint ($) {
    my ($type_name) = @_;
    return $type_name =~ /^\w+\[[\w:_\d]+\]$/;
}

# }}}

# {{{ - built-in types and subtypes

## --------------------------------------------------------
## some basic built-in types (mostly taken from Moose)
## --------------------------------------------------------

type 'Any'  => where { 1 }; # meta-type including all
type 'Item' => where { 1 }; # base-type 

subtype 'Undef'   => as 'Item' => where { !defined($_) };
subtype 'Defined' => as 'Item' => where {  defined($_) };

subtype 'Bool'
    => as 'Item' 
    => where { !defined($_) || $_ eq "" || "$_" eq '1' || "$_" eq '0' };

subtype 'Value' 
    => as 'Defined' 
    => where { !ref($_) };
    
subtype 'Ref'
    => as 'Defined' 
    => where {  ref($_) };

subtype 'Str' 
    => as 'Value' 
    => where { 1 };

subtype 'Num' 
    => as 'Value' 
    => where { "$_" =~ /^-?[\d\.]+$/ };
    
subtype 'Int' 
    => as 'Num'   
    => where { "$_" =~ /^-?[0-9]+$/ };

subtype 'ScalarRef' => as 'Ref' => where { ref($_) eq 'SCALAR' };
subtype 'ArrayRef'  => as 'Ref' => where { ref($_) eq 'ARRAY'  }; 
subtype 'HashRef'   => as 'Ref' => where { ref($_) eq 'HASH'   }; 
subtype 'CodeRef'   => as 'Ref' => where { ref($_) eq 'CODE'   }; 
subtype 'RegexpRef' => as 'Ref' => where { ref($_) eq 'Regexp' }; 
subtype 'GlobRef'   => as 'Ref' => where { ref($_) eq 'GLOB'   };

subtype 'FileHandle' 
    => as 'GlobRef' 
    => where { ref($_) eq 'GLOB' };

subtype 'Object' 
    => as 'Ref' 
    => where { ref($_) && 
               ref($_) ne 'Regexp' && 
               ref($_) ne 'ARRAY' && 
               ref($_) ne 'SCALAR' && 
               ref($_) ne 'CODE' && 
               ref($_) ne 'HASH'};

subtype 'ClassName' 
    => as 'Str' 
    => where { ref($_[0]) && ref($_[0]) eq $_[1] };

# accesor to all the built-in types
{
    my @BUILTINS = list_all_type_constraints();
    sub list_all_builtin_type_constraints { @BUILTINS }
}

# }}}

1;
__END__
=pod

=head1 NAME

Coat::Types - Type constraint system for Coat

=head1 NOTE

This is a rewrite of Moose::Util::TypeConstraint for Coat.

=head1 SYNOPSIS

  use Coat::Types;

  type 'Num' => where { Scalar::Util::looks_like_number($_) };

  subtype 'Natural'
      => as 'Num'
      => where { $_ > 0 };

  subtype 'NaturalLessThanTen'
      => as 'Natural'
      => where { $_ < 10 }
      => message { "This number ($_) is not less than ten!" };

  coerce 'Num'
      => from 'Str'
        => via { 0+$_ };

  enum 'RGBColors' => qw(red green blue);

=head1 DESCRIPTION

This module provides Coat with the ability to create custom type
contraints to be used in attribute definition.

=head2 Important Caveat

This is B<NOT> a type system for Perl 5. These are type constraints,
and they are not used by Coat unless you tell it to. No type
inference is performed, expression are not typed, etc. etc. etc.

This is simply a means of creating small constraint functions which
can be used to simplify your own type-checking code, with the added 
side benefit of making your intentions clearer through self-documentation.

=head2 Slightly Less Important Caveat

It is B<always> a good idea to quote your type and subtype names.

This is to prevent perl from trying to execute the call as an indirect
object call. This issue only seems to come up when you have a subtype
the same name as a valid class, but when the issue does arise it tends
to be quite annoying to debug.

So for instance, this:

  subtype DateTime => as Object => where { $_->isa('DateTime') };

will I<Just Work>, while this:

  use DateTime;
  subtype DateTime => as Object => where { $_->isa('DateTime') };

will fail silently and cause many headaches. The simple way to solve
this, as well as future proof your subtypes from classes which have
yet to have been created yet, is to simply do this:

  use DateTime;
  subtype 'DateTime' => as 'Object' => where { $_->isa('DateTime') };

=head2 Default Type Constraints

This module also provides a simple hierarchy for Perl 5 types, here is 
that hierarchy represented visually.

  Any
  Item
      Bool
      Undef
      Defined
          Value
              Num
                Int
              Str
                ClassName
          Ref
              ScalarRef
              ArrayRef[`a]
              HashRef[`a]
              CodeRef
              RegexpRef
              GlobRef
              Object

=head2 Type Constraint Naming 

Since the types created by this module are global, it is suggested 
that you namespace your types just as you would namespace your 
modules. So instead of creating a I<Color> type for your B<My::Graphics>
module, you would call the type I<My::Graphics::Color> instead.

=head1 FUNCTIONS

=head2 Type Constraint Constructors

The following functions are used to create type constraints.
They will then register the type constraints in a global store
where Coat can get to them if it needs to.

See the L<SYNOPSIS> for an example of how to use these.

=over 4

=item B<type ($name, $where_clause)>

This creates a base type, which has no parent.

=item B<subtype ($name, $parent, $where_clause, ?$message)>

This creates a named subtype.

=item B<enum ($name, @values)>

This will create a basic subtype for a given set of strings.
The resulting constraint will be a subtype of C<Str> and
will match any of the items in C<@values>. It is case sensitive.
See the L<SYNOPSIS> for a simple example.

B<NOTE:> This is not a true proper enum type, it is simple
a convient constraint builder.

=item B<as>

This is just sugar for the type constraint construction syntax.

=item B<where>

This is just sugar for the type constraint construction syntax.

=item B<message>

This is just sugar for the type constraint construction syntax.

=back

=head2 Type Coercion Constructors

Type constraints can also contain type coercions as well. If you
ask your accessor to coerce, then Coat will run the type-coercion
code first, followed by the type constraint check. This feature
should be used carefully as it is very powerful and could easily
take off a limb if you are not careful.

See the L<SYNOPSIS> for an example of how to use these.

=over 4

=item B<coerce>

=item B<from>

This is just sugar for the type coercion construction syntax.

=item B<via>

This is just sugar for the type coercion construction syntax.

=back

=head2 Type Constraint Construction & Locating

=over 4

=item B<find_type_constraint ($type_name)>

This function can be used to locate a specific type constraint
meta-object, of the class L<Coat::Meta::TypeConstraint> or a
derivative. What you do with it from there is up to you :)

=item B<register_type_constraint ($type_object)>

This function will register a named type constraint with the type registry.

=item B<list_all_type_constraints>

This will return a list of type constraint names, you can then
fetch them using C<find_type_constraint ($type_name)> if you
want to.

=item B<export_type_constraints_as_functions>

This will export all the current type constraints as functions
into the caller's namespace. Right now, this is mostly used for
testing, but it might prove useful to others.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Alexis Sukrieh E<lt>sukria@sukria.netE<gt> ;
based on the work done by Stevan Little E<lt>stevan@iinteractive.comE<gt> 
on Moose::Util::TypeConstraint

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Edenware - Alexis Sukrieh

L<http://www.edenware.fr> - L<http://www.sukria.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
