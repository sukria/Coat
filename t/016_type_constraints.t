use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
    use_ok('Coat');           
}

{
    package Foo;
    use Coat;
    
    has 'bar' => (is => 'ro', required => 1);
    has 'baz' => (is => 'rw', default => 100, required => 1); 
    has 'boo' => (is => 'rw', lazy => 1, default => 50, required => 1);       
}

{
    my $foo = Foo->new(bar => 10, baz => 20, boo => 100);
    isa_ok($foo, 'Foo');
    
    is($foo->bar, 10, '... got the right bar');
    is($foo->baz, 20, '... got the right baz');    
    is($foo->boo, 100, '... got the right boo');        
}

{
    my $foo = Foo->new(bar => 10, boo => 5);
    isa_ok($foo, 'Foo');
    
    is($foo->bar, 10, '... got the right bar');
    is($foo->baz, 100, '... got the right baz');    
    is($foo->boo, 5, '... got the right boo');            
}

{
    my $foo = Foo->new(bar => 10);
    isa_ok($foo, 'Foo');
    
    is($foo->bar, 10, '... got the right bar');
    is($foo->baz, 100, '... got the right baz');    
    is($foo->boo, 50, '... got the right boo');            
}

eval { Foo->new(bar => 10, baz => undef) };
ok( $@ =~ /^Attribute \(baz\) is required and cannot be undef/, 
    '... must supply all the required attribute');

eval { Foo->new(bar => 10, boo => undef) };
ok( $@ =~ /^Attribute \(boo\) is required and cannot be undef/, 
    '... must supply all the required attribute');

eval { Foo->new };
ok( $@ =~ /^Attribute \(bar\) is required/, 
    '... must supply all the required attribute');

