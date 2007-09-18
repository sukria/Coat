#!/usr/bin/perl

use Test::More tests => 5;

# for classes ...
{
    package Foo;
    use Coat;
    
    eval '$foo = 5;';
    ::ok($@, '... got an error because strict is on');
    ::like($@, qr/Global symbol \"\$foo\" requires explicit package name at/, '... got the right error');
    
    {
        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };

        ::ok(!$warn, '... no warning yet');
                
        eval 'my $bar = 1 + "hello"';
        
        ::ok($warn, '... got a warning');
        ::like($warn, qr/Argument \"hello\" isn\'t numeric in addition \(\+\)/, '.. and it is the right warning');
    }
}
