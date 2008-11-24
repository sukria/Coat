package Coat::Meta::TypeConstraint;

use strict;
use warnings;
use Carp 'confess';

sub new { 
    my ($class, %values) = @_;
    my $self = { %values }; 
    return bless $self, $class;
}

# accessors
sub name         { $_[0]->{name}         ||= $_[1] }
sub validation   { $_[0]->{validation}   ||= $_[1] }
sub message      { $_[0]->{message}      ||= $_[1] }
sub parent       { $_[0]->{parent}       ||= $_[1] }

sub coercion_map { 
    my ($self, $map) = @_;
    if (@_ == 1) {
        return $self->{coercion_map};
    }
    else {
        return $self->{coercion_map} = $map; 
    }
}

# coerce the given value with the first matching type
sub coerce {
    my ($self, $value) = @_;

    # for each source registered, try coercion if the source is a valid type
    local $_ = $value;
    foreach my $source (keys %{ $self->coercion_map }) {
        # if current value passes the current source check, coercing
        my $tc = Coat::Types::find_type_constraint($source);
        return $self->{coercion_map}{$source}->($value) 
            if $tc->silent_validate($value);
    }
    return $value;
}

# check the value through the type constraints
sub silent_validate { 
    my ($self, $value) = @_;
    local $_ = $value;

    # validates the parent's type-constraint if exists
    if (defined $self->parent) {
        Coat::Types::find_type_constraint( $self->parent )->silent_validate( $value )
            or return 0;
    }
    return $self->validation->($value);
}

sub validate {
    my ($self, $value) = @_;
    unless ($self->silent_validate($value)) {
        local $_ = $value;
        my $msg = (defined $self->message) 
            ? $self->message->()
            : "Value '" .(defined $value ? $value : 'undef')
            ."' does not validate type constraint '".$self->name."'";
        confess $msg;
    }
    return 1;
}

sub has_coercion {
    my ($self) = @_;
    return defined $self->coercion_map;
}

1;
__END__
=pod

=head1 NAME

Coat:Meta::TypeConstraint - The Coat Type Constraint metaclass

=head1 DESCRIPTION

For the most part, the only time you will ever encounter an
instance of this class is if you are doing some serious deep
introspection. This API should not be considered final, but
it is B<highly unlikely> that this will matter to a regular
Coat user.

=head1 METHODS

=over 4

=item B<new>

Constructor

=item B<coerce ($value)>

This will apply the type-coercion if applicable.

=item B<validate ($value)>

If the C<$value> passes the constraint, C<undef> will be
returned. If the C<$value> does B<not> pass the constraint, then
the C<message> will be used to construct a custom error message.

=item B<has_coercion>
Return true if coercion has been defined, false otherwise.

=back

=head1 AUTHOR

Alexis Sukrieh E<lt>sukria@sukria.netE<gt> ;
based on the work done by Stevan Little E<lt>stevan@iinteractive.comE<gt> 
on Moose::Meta::TypeConstraint

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Edenware - Alexis Sukrieh

L<http://www.edenware.fr> - L<http://www.sukria.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

