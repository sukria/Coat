#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Scalar::Util ();

BEGIN {
    use_ok('Coat::Types');
}

my $SCALAR_REF = \(my $var);

no warnings 'once'; # << I *hates* that warning ...
my $GLOB_REF   = \*GLOB_REF;

my $fh;
open($fh, '<', $0) || die "Could not open $0 for the test";

Coat::Types->export_type_constraints_as_functions();

ok(defined Any(0),               '... Any accepts anything');
ok(defined Any(100),             '... Any accepts anything');
ok(defined Any(''),              '... Any accepts anything');
ok(defined Any('Foo'),           '... Any accepts anything');
ok(defined Any([]),              '... Any accepts anything');
ok(defined Any({}),              '... Any accepts anything');
ok(defined Any(sub {}),          '... Any accepts anything');
ok(defined Any($SCALAR_REF),     '... Any accepts anything');
ok(defined Any($GLOB_REF),       '... Any accepts anything');
ok(defined Any($fh),             '... Any accepts anything');
ok(defined Any(qr/../),          '... Any accepts anything');
ok(defined Any(bless {}, 'Foo'), '... Any accepts anything');
ok(defined Any(undef),           '... Any accepts anything');


ok(defined Item(0),               '... Item is the base type, so accepts anything');
ok(defined Item(100),             '... Item is the base type, so accepts anything');
ok(defined Item(''),              '... Item is the base type, so accepts anything');
ok(defined Item('Foo'),           '... Item is the base type, so accepts anything');
ok(defined Item([]),              '... Item is the base type, so accepts anything');
ok(defined Item({}),              '... Item is the base type, so accepts anything');
ok(defined Item(sub {}),          '... Item is the base type, so accepts anything');
ok(defined Item($SCALAR_REF),     '... Item is the base type, so accepts anything');
ok(defined Item($GLOB_REF),       '... Item is the base type, so accepts anything');
ok(defined Item($fh),             '... Item is the base type, so accepts anything');
ok(defined Item(qr/../),          '... Item is the base type, so accepts anything');
ok(defined Item(bless {}, 'Foo'), '... Item is the base type, so accepts anything');
ok(defined Item(undef),           '... Item is the base type, so accepts anything');

ok(defined Defined(0),               '... Defined accepts anything which is defined');
ok(defined Defined(100),             '... Defined accepts anything which is defined');
ok(! defined Defined(undef),          '... Defined accepts anything which is defined');

ok(!defined Undef(0),               '... Undef accepts anything which is not defined');
ok(!defined Undef(100),             '... Undef accepts anything which is not defined');
ok(!defined Undef(''),              '... Undef accepts anything which is not defined');
ok(!defined Undef('Foo'),           '... Undef accepts anything which is not defined');

ok(defined Bool(0),                 '... Bool rejects anything which is not a 1 or 0 or "" or undef');
ok(defined Bool(1),                 '... Bool rejects anything which is not a 1 or 0 or "" or undef');
ok(!defined Bool(100),              '... Bool rejects anything which is not a 1 or 0 or "" or undef');
ok(defined Bool(''),                '... Bool rejects anything which is not a 1 or 0 or "" or undef');
ok(!defined Bool('Foo'),            '... Bool rejects anything which is not a 1 or 0 or "" or undef');

ok(defined Value(0),                 '... Value accepts anything which is not a Ref');
ok(defined Value(100),               '... Value accepts anything which is not a Ref');
ok(defined Value(''),                '... Value accepts anything which is not a Ref');
ok(defined Value('Foo'),             '... Value accepts anything which is not a Ref');

ok(!defined Ref(0),               '... Ref accepts anything which is not a Value');
ok(!defined Ref(100),             '... Ref accepts anything which is not a Value');
ok(!defined Ref(''),              '... Ref accepts anything which is not a Value');
ok(!defined Ref('Foo'),           '... Ref accepts anything which is not a Value');
ok(defined Ref([]),               '... Ref rejects anything which is not a Ref');
ok(defined Ref({}),               '... Ref rejects anything which is not a Ref');
ok(defined Ref(sub {}),           '... Ref rejects anything which is not a Ref');

ok(defined Int(0),                 '... Int accepts anything which is an Int');
ok(defined Int(100),               '... Int accepts anything which is an Int');
ok(!defined Int(0.5),              '... Int accepts anything which is not a Int');
ok(!defined Int('sukria'),              '... Int accepts anything which is not a Int');
__END__
ok(!defined Int(100.01),           '... Int accepts anything which is not a Int');
ok(!defined Int(''),               '... Int rejects anything which is not a Int');
ok(!defined Int('Foo'),            '... Int rejects anything which is not a Int');
ok(!defined Int([]),               '... Int rejects anything which is not a Int');
ok(!defined Int({}),               '... Int rejects anything which is not a Int');
ok(!defined Int(sub {}),           '... Int rejects anything which is not a Int');
ok(!defined Int($SCALAR_REF),      '... Int rejects anything which is not a Int');
ok(!defined Int($GLOB_REF),        '... Int rejects anything which is not a Int');
ok(!defined Int($fh),              '... Int rejects anything which is not a Int');
ok(!defined Int(qr/../),           '... Int rejects anything which is not a Int');
ok(!defined Int(bless {}, 'Foo'),  '... Int rejects anything which is not a Int');

ok(defined Num(0),                 '... Num accepts anything which is an Num');
ok(defined Num(100),               '... Num accepts anything which is an Num');
ok(defined Num(0.5),               '... Num accepts anything which is an Num');
ok(defined Num(100.01),            '... Num accepts anything which is an Num');
ok(!defined Num(''),               '... Num rejects anything which is not a Num');
ok(!defined Num('Foo'),            '... Num rejects anything which is not a Num');
ok(!defined Num([]),               '... Num rejects anything which is not a Num');
ok(!defined Num({}),               '... Num rejects anything which is not a Num');
ok(!defined Num(sub {}),           '... Num rejects anything which is not a Num');
ok(!defined Num($SCALAR_REF),      '... Num rejects anything which is not a Num');
ok(!defined Num($GLOB_REF),        '... Num rejects anything which is not a Num');
ok(!defined Num($fh),              '... Num rejects anything which is not a Num');
ok(!defined Num(qr/../),           '... Num rejects anything which is not a Num');
ok(!defined Num(bless {}, 'Foo'),  '... Num rejects anything which is not a Num');
ok(!defined Num(undef),            '... Num rejects anything which is not a Num');

ok(defined Str(0),                 '... Str accepts anything which is a Str');
ok(defined Str(100),               '... Str accepts anything which is a Str');
ok(defined Str(''),                '... Str accepts anything which is a Str');
ok(defined Str('Foo'),             '... Str accepts anything which is a Str');
ok(!defined Str([]),               '... Str rejects anything which is not a Str');
ok(!defined Str({}),               '... Str rejects anything which is not a Str');
ok(!defined Str(sub {}),           '... Str rejects anything which is not a Str');
ok(!defined Str($SCALAR_REF),      '... Str rejects anything which is not a Str');
ok(!defined Str($fh),              '... Str rejects anything which is not a Str');
ok(!defined Str($GLOB_REF),        '... Str rejects anything which is not a Str');
ok(!defined Str(qr/../),           '... Str rejects anything which is not a Str');
ok(!defined Str(bless {}, 'Foo'),  '... Str rejects anything which is not a Str');
ok(!defined Str(undef),            '... Str rejects anything which is not a Str');

ok(!defined ScalarRef(0),                '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(100),              '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(''),               '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef('Foo'),            '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef([]),               '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef({}),               '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(sub {}),           '... ScalarRef rejects anything which is not a ScalarRef');
ok(defined ScalarRef($SCALAR_REF),       '... ScalarRef accepts anything which is a ScalarRef');
ok(!defined ScalarRef($GLOB_REF),        '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef($fh),              '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(qr/../),           '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(bless {}, 'Foo'),  '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(undef),            '... ScalarRef rejects anything which is not a ScalarRef');

ok(!defined ArrayRef(0),                '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(100),              '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(''),               '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef('Foo'),            '... ArrayRef rejects anything which is not a ArrayRef');
ok(defined ArrayRef([]),                '... ArrayRef accepts anything which is a ArrayRef');
ok(!defined ArrayRef({}),               '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(sub {}),           '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef($SCALAR_REF),      '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef($GLOB_REF),        '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef($fh),              '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(qr/../),           '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(bless {}, 'Foo'),  '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(undef),            '... ArrayRef rejects anything which is not a ArrayRef');

ok(!defined HashRef(0),                '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(100),              '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(''),               '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef('Foo'),            '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef([]),               '... HashRef rejects anything which is not a HashRef');
ok(defined HashRef({}),                '... HashRef accepts anything which is a HashRef');
ok(!defined HashRef(sub {}),           '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef($SCALAR_REF),      '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef($GLOB_REF),        '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef($fh),              '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(qr/../),           '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(bless {}, 'Foo'),  '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(undef),            '... HashRef rejects anything which is not a HashRef');

ok(!defined CodeRef(0),                '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(100),              '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(''),               '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef('Foo'),            '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef([]),               '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef({}),               '... CodeRef rejects anything which is not a CodeRef');
ok(defined CodeRef(sub {}),            '... CodeRef accepts anything which is a CodeRef');
ok(!defined CodeRef($SCALAR_REF),      '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef($GLOB_REF),        '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef($fh),              '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(qr/../),           '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(bless {}, 'Foo'),  '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(undef),            '... CodeRef rejects anything which is not a CodeRef');

ok(!defined RegexpRef(0),                '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef(100),              '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef(''),               '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef('Foo'),            '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef([]),               '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef({}),               '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef(sub {}),           '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef($SCALAR_REF),      '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef($GLOB_REF),        '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef($fh),              '... RegexpRef rejects anything which is not a RegexpRef');
ok(defined RegexpRef(qr/../),            '... RegexpRef accepts anything which is a RegexpRef');
ok(!defined RegexpRef(bless {}, 'Foo'),  '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef(undef),            '... RegexpRef rejects anything which is not a RegexpRef');

ok(!defined Object(0),                '... Object rejects anything which is not blessed');
ok(!defined Object(100),              '... Object rejects anything which is not blessed');
ok(!defined Object(''),               '... Object rejects anything which is not blessed');
ok(!defined Object('Foo'),            '... Object rejects anything which is not blessed');
ok(!defined Object([]),               '... Object rejects anything which is not blessed');
ok(!defined Object({}),               '... Object rejects anything which is not blessed');
ok(!defined Object(sub {}),           '... Object rejects anything which is not blessed');
ok(!defined Object($SCALAR_REF),      '... Object rejects anything which is not blessed');
ok(!defined Object($GLOB_REF),        '... Object rejects anything which is not blessed');
ok(!defined Object($fh),              '... Object rejects anything which is not blessed');
ok(!defined Object(qr/../),           '... Object rejects anything which is not blessed');
ok(defined Object(bless {}, 'Foo'),   '... Object accepts anything which is blessed');
ok(!defined Object(undef),             '... Object accepts anything which is blessed');

close($fh) || die "Could not close the filehandle $0 for test";
