package Coat::Object;

use strict;
use warnings;
use Coat::Meta;
use Carp 'confess';

# this is the mother-class of each Coat objects, it provides
# basic instance methods such as a constructor

# The default constructor
sub new {
    my ( $class, @args ) = @_;

    # create the newborn
    my $self = {};
    bless $self, $class;

    # parse and prepare the args
    my $args = $self->build_args(@args);

    # init the object
    $self->init($args);

    # done
    return $self;
}

sub make_clone { 
    my ($self) = @_;
    my $class = ref($self);
    my $clone = $class->new(%$self);
    return $clone;
}

sub build_args {
    my ($self, @args) = @_;
    my $class = ref($self);

    my $args;
    $args = {@args} if @args % 2 == 0;

    # if BUILDARGS exists, look or it and run it
    if ($self->can('BUILDARGS')) {
        foreach my $pkg (reverse Coat::Meta->linearized_isa($class)) {
            my $buildargs_sub;
            { 
                no strict 'refs'; 
                $buildargs_sub = *{$pkg."::BUILDARGS"}; 
            }
            if (defined &$buildargs_sub) {
                $args = $self->$buildargs_sub(@args);
                last;
            }
        }
    }

    # now check everything is OK with the args
    unless (defined $args) {
        if (@args == 1) {
            if (ref($args[0]) ne 'HASHREF') {
                confess "Single argument must be an HASHREF";
            }
            else {
                $args = $args[0];
            }
        }
        else {
            confess "Invalid arguments";
        }
    }
    return $args;
}

# returns the meta-class description of that instance
sub meta {
    my ($self) = @_;
    return Coat::Meta->class( ref($self) );
}

# init an instance : put default values and set values
# given at instanciation time
sub init {
    my ( $self, $attrs ) = @_;
    my $class = ref $self;

    my $class_attr = Coat::Meta->all_attributes( $class );
    
    # setting all default values
    foreach my $attr ( keys %{$class_attr} ) {
        my $meta = $class_attr->{$attr};

        confess "You cannot have lazy attribute ($attr) without specifying a default value for it" 
            if ($meta->{lazy} && !exists($meta->{default}));

        # handling default values for non-lazy slots
        if ( (! $meta->{'lazy'}) && defined $meta->{'default'} ) {

            # saving original permission and setting it to read/write
            my $is = $meta->{'is'};
            $meta->{'is'} = 'rw';
            
            # set default value
            $self->$attr( Coat::Meta->attr_default( $self, $attr) ); 

            # restoring original permissions
            $meta->{'is'} = $is;
        }
         
        # a required read-only field must have a default value or be set at
        # instanciation time
        confess "Attribute ($attr) is required"
            if ($meta->{'required'} &&
                $meta->{'is'} eq 'ro' &&
                (! exists $meta->{'default'}) && 
                (! exists $attrs->{$attr}));
    }

    # setting values given at instanciation time
    foreach my $attr ( keys %$attrs ) {
        my $is = $class_attr->{$attr}{'is'};
        
        $class_attr->{$attr}{'is'} = 'rw';
        $self->$attr( $attrs->{$attr} );
        $class_attr->{$attr}{'is'} = $is;
    }

    $self->BUILDALL($attrs);
    return $self;
}

sub BUILDALL { _run_for_all('BUILD', @_) }

sub DEMOLISHALL { _run_for_all('DEMOLISH', @_) }

sub DESTROY { goto &DEMOLISHALL }

# taken from Moose::Object
sub dump { 
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Maxdepth = shift if @_;
    Data::Dumper::Dumper $self;
}

# returns a new object whose attribute values are
# equal to those of self
sub clone {
    my ($self) = @_;
    eval "use Clone";
    confess "Module Clone is needed for cloning object: $@" if ($@);
    return Clone::clone($self);
}

# private

# This is done to let us implement easily the BUILDARGS/BUILD/DEMOLISH stuff 
# It must behave the same: with inheritance in mind.
# Thanks again to the Moose team for the idea of *ALL() methods.

sub _run_for_all {
    my ($method_name, $self, $params) = @_;
    my $class = ref($self);

    return unless $self->can($method_name);

    my $sub;
    foreach my $pkg (reverse Coat::Meta->linearized_isa($class)) {
        { 
            no strict 'refs'; 
            $sub = *{$pkg."::${method_name}"}; 
        }
        $self->$sub( %$params ) if defined &$sub;
    }
}



# end Coat::Object
1;
__END__

=head1 NAME

Coat::Object - The mother class for each class that uses Coat

=head1 DESCRIPTION

When a class is described with Coat, each instance of that class will inherit
from Coat::Object.

This is the mother-class for each Coat-created objects, it provides a basic default
constructor and access to the meta-class.

=head1 METHODS

=head2 new

This is the default constructor, it creates a new object for your class and
calls init with the arguments given.

=head2 init

This method initialize the instance: basically, setting default values to
attributes and setting values received (passed to the "new" method).

=head2 meta

Returns the meta-calss description: attributes declared with properties.

=head1 SEE ALSO

See C<Coat>, the meta-class for Coat::Object's.

See also C<Moose>, the mother of Coat.

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
