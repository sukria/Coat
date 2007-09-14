use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Coat',
    VERSION_FROM => 'lib/Coat.pm',
    ABSTRACT => 'Light meta class for writing fast OO Perl code',
    test => {TESTS => join( ' ', glob( 't/*.t' ))},
);
