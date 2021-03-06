#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
    use_ok('Coat');
}

{
    package TouchyBase;
    use Coat;

    has x => ( is => 'rw', default => 0 );

    sub inc { 
        $_[0]->x( 1 + $_[0]->x );
    }

    sub scalar_or_array {
        wantarray ? (qw/a b c/) : "x";
    }

    sub void {
        die "this must be void context" if defined wantarray;
    }

    package AfterSub;
    use Coat;
    extends "TouchyBase";

    after scalar_or_array => sub {
        my $self = shift;
        $self->inc;        
    };

    after void => sub {
        my $self = shift;
        $self->inc;        
    };
}

my $base = TouchyBase->new;
my $after = AfterSub->new;

ok(($base->x) == 0, 'default value is affected to x');

foreach my $obj ( $base, $after ) {
    my $class = ref $obj;
    my @array = $obj->scalar_or_array;
    my $scalar = $obj->scalar_or_array;

    is_deeply(\@array, [qw/a b c/], "array context ($class)");
    is($scalar, "x", "scalar context ($class)");

    {
        local $@;
        eval { $obj->void };
        ok( !$@, "void context ($class)" );
    }

    if ( $obj->isa("AfterSub") ) {
        is( $obj->x, 3, "methods were wrapped" );
    }
}

