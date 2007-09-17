#!/usr/bin/perl

# classes 

package Builder;
use Coat;

var 'value' => (type => 'String', default => 'stuff');
var 'number' => (type => 'Int', default => 0);
var 'salt' => (type => 'String', default => 'xz' );

sub hello
{
    my ($self, $word) = @_;
    return "Hello $word ; value is : ".$self->value;
}

sub crypt
{
    my ($self) = @_;
    return crypt( $self->value, $self->salt );
}

sub reverse
{
    my ($self) = @_;
    return ( join ( "", reverse( split( //, $self->value ) ) ) );
}

sub add
{
    my ($self, $number) = @_;
    return $self->number($self->number + $number);
}

sub minus 
{
    my ($self, $number) = @_;
    return $self->number($self->number - $number);
}

package Fuzzer;

use Coat;
extends 'Builder';

before 'reverse' => sub {
    my ($self) = @_;
    $self->value( "12345" );
};

before 'reverse' => sub {
    my ($self) = @_;
    $self->value('sukria');
};

after 'crypt' => sub {
    my ($self, $result, @args) = @_;
    return "after 1: $result";
};

after 'crypt' => sub {
    my ($self, $result, @args) = @_;
    return "after 2: $result";
};


around 'hello' => sub {
    my $orig = shift;
    my ($self, $word) = @_;

    my $orig_out = $self->$orig($word);
    return "H3LL0 : $word (was \"$orig_out\")";
};

# add another time the value _but_ don't set the value 
# in the isntance
around 'add' => sub {
    my $orig = shift;
    my ($self, $value) = @_;
    my $val = $self->$orig($value);
    return $val + $value;
};

after 'minus' => sub {
    my ($self, $result, $value) = @_;
    return $result - $value;
};

package FuzzerNew;

use Coat;
extends 'Fuzzer';

after 'minus' => sub {
    my ($self, $result, $value) = @_;
    return 1000;
};

# test

package main;

use strict;
use warnings;
use Test::Simple qw(no_plan);

my $builder = new Builder value => "Coat";

ok( defined $builder, 'new Builder' );
ok( $builder->crypt, '$builder->crypt');
ok( $builder->reverse, '$builder->reverse');

my $fuzzer = new Fuzzer value => "Coat";
ok( defined $fuzzer, 'new Fuzzer' );

ok( $fuzzer->reverse, '$fuzzer->reverse');
ok( ($fuzzer->reverse ne $builder->reverse), 'reverse changed');
ok( $fuzzer->reverse eq 'airkus', '$fuzzer->reverse eq : '.$fuzzer->reverse);
ok( $fuzzer->value eq 'sukria', '$fuzzer->value eq sukria' );

my $crypt_orig = $builder->crypt;
ok ($crypt_orig, 'crypt : '.$crypt_orig);

my $crypt_new = $fuzzer->crypt;
ok( $crypt_new, "crypt_new: $crypt_new");

ok(($crypt_orig ne $crypt_new), '$crypt_orig != $crypt_new');
ok($crypt_new =~ /^after 2: /, '$crypt_new =~ /after 2: /'.$crypt_new);


ok( $builder->hello('builder'), 
    '$builder->hello(builder) = '.$builder->hello('builder'));
ok( $fuzzer->hello('fuzzer'), 
    '$fuzzer->hello(fuzzer) = '.$fuzzer->hello('fuzzer'));
ok(($builder->hello(1) ne $fuzzer->hello(1)), 
    '$builder->hello ne $fuzzer->hello');

$builder->number(2);
$fuzzer->number(2);

ok( $builder->add(4) == 6, '$builder->add(4) == 6' );
ok($builder->number == 6, '$builder->number == 6');

ok( $fuzzer->add(4) == 10, '$fuzzer->add(4) == 10' );
ok( $fuzzer->number == 6, 
    "\$fuzzer->number == 6 (the after hook didn't touch it)");

ok( $builder->minus(2) == 4, '$builder->minus(2) == 4');

ok( $fuzzer->minus(2) == 2, '$fuzzer->minus(2) == 2');

my $fu2 = new FuzzerNew value => 'toto', number => 10;
ok($fu2->minus(2), 'FuzzerNew->minus');
