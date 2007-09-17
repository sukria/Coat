package Coat::Object;

# this is the mother-class of each Coat objects, it provides 
# basic instance methods such as a constructor

# The default constructor
sub new {
    my ( $class, %args ) = @_;

    my $self = {};
    bless $self, $class;

    $self->init(%args);

    return $self;
}


# returns the attributes descriptions for the class of that instance
sub attrs {
    my ($self) = @_;
    return Coat::class( ref( $self ) );
}

# tells if the given attribute is delcared for the class of that instance
sub has {
    my ( $self, $var ) = @_;
    return Coat::class_has_attr( ref( $self ), $var );
}

# init an instance : put default values and set values
# given at instanciation time
sub init {
    my ( $self, %attrs ) = @_;

    # default values
    my $class_attr = $self->attrs;
    foreach my $attr ( keys %{$class_attr} ) {
        if ( defined $class_attr->{$attr}{default} ) {
            $self->$attr( $class_attr->{$attr}{default} );
        }
    }

    # forced values
    foreach my $attr ( keys %attrs ) {
        $self->$attr( $attrs{$attr} );
    }
}

# end Coat::Object
1;
__END__

