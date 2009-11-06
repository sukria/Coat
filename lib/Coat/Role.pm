package Coat::Role;
use strict;
use warnings;

use Exporter;
use base 'Exporter';
use vars qw(@EXPORT);

@EXPORT = (qw(requires has));

use Coat;
use Coat::Role::Object;

sub has { 
    my ($attr, %options) = @_;
    $options{'!caller'} = caller;
    Coat::has($attr, %options) ;
}

sub import {
    my $class = shift;
    my $caller = caller;
    return if $caller eq 'main';

    # import strict and warnings
    strict->import;
    warnings->import;

    { no strict 'refs'; @{"${caller}::ISA"} = ('Coat::Role::Object'); }

    $class->export_to_level( 1, @_ );
}

sub requires { 1 }

1;
