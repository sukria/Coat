#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib', '../lib';

use Test::More tests => 5;



{
    package Bar;
    use Coat;
    
    eval { extends 'Foo'; };
    ::ok(!$@, '... loaded Foo superclass correctly');
}

{
    package Baz;
    use Coat;
    
    eval { extends 'Bar'; };
    ::ok(!$@, '... loaded (inline) Bar superclass correctly');
}

{
    package Foo::Bar;
    use Coat;
    
    eval { extends 'Foo', 'Bar'; };
    ::ok(!$@, '... loaded Foo and (inline) Bar superclass correctly');
}

{
    package Bling;
    use Coat;
    
    eval { extends 'No::Class'; };
    ::ok($@, '... could not find the superclass (as expected)');
    ::like($@, qr/^Could not load class \(No\:\:Class\) because \:/, '... and got the error we expected');
}

