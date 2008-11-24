use Test::More 'no_plan';
use strict;
use warnings;

{
    package A;
    use Coat;
    
    has array_of_str => (
        is => 'rw',
        isa => 'ArrayRef[Str]',
    );
    
    has hash_of_a => (is => 'rw', isa => 'HashRef[A]');
    has hash_of_num => (is => 'rw', isa => 'HashRef[Num]');
    has 'many_a' => (is => 'rw', isa => 'ArrayRef[A]');

    package B;
    use Coat;

    has x => (is => 'rw', isa => 'Num');
}


my $a = new A;
ok (defined $a, 'defined $a' );

my $many_a = [ map { A->new() } (1 .. 10) ];
my $many_b = [ map { B->new() } (1 .. 10) ];

eval { $a->many_a($many_a) };
is($@, '', 'array of objects A accepted');

eval { $a->many_a($many_b) };
ok($@, 'array of objects B refused');

eval { $a->hash_of_a( { one => A->new, two => A->new})};
is($@, '', 'hash of A accepted');

eval { $a->hash_of_a( { one => A->new, two => B->new})};
ok($@, 'Hash of mixed A and B objects refused : ' );

eval { $a->hash_of_a( $many_a )};
ok($@, 'value refused : not an HashRef' );

eval { $a->hash_of_num( { one => 1, two => 2, three => 3 } )};
is($@, '', 'hash of Num accepted');

eval { $a->hash_of_num( { one => 1, two => 2, three => "foo" } )};
ok($@, 'hash mixed of num and str refused for HashRef[Num]' );

ok( $a->array_of_str(['Foo', 'Bar', 'Baz']), 'array_of_str accepted' );

eval { $a->array_of_str(23) };
ok( $@, 
    'array_of_str blocked : not an arrayref : ');

eval { $a->array_of_str([23, 'Foo', [43, 42], sub { 1 + 2 + $_[0]} ]) };
ok( $@ =~ /failed with value ARRAY/, 
    'array_of_str blocked : not an arrayref of Str : ' );


