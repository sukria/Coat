use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Coat',
    VERSION_FROM => 'lib/Coat.pm',
    ABSTRACT => 'Light meta class for writing Moose compatible code',
    PREREQ_PM => {
        'Scalar::Util' => 0,
    },
    test => {TESTS => join( ' ', glob( 't/*.t' )).' '.join(' ', glob('t/*/*.t'))},
);
