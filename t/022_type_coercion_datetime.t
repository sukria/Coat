use Test::More 'no_plan';
use strict;
use warnings;

use Coat::Types;
use Coat::Meta::TypeConstraint;

BEGIN { use_ok 'IO::File' }

subtype 'IO::File'
    => as 'Object'
    => where {$_->isa('IO::File')};
    

coerce 'IO::File'
    => from 'Str'
    => via {
        IO::File->new()
    };

{
    package A;
    use Coat;
    has 'file' => (is => 'rw', isa => 'IO::File', coerce => 1);
}


my $a = A->new();
eval {
    $a->file('foo.file');
};
is($@,'','coercion succeeded');

ok($a->file->isa('IO::File'), 'file is a IO::File object');
