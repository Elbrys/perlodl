use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Brocade::BSC',
    AUTHOR           => q{laird pruiksma <pruiklw@cpan.org>},
    VERSION_FROM     => 'lib/Brocade/BSC.pm',
    ABSTRACT_FROM    => 'lib/Brocade/BSC.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'         => 1.36,
        'Carp::Assert' => 0.21,
        'JSON'         => 2.90,
        'Readonly'     => 2.00,
        'XML::Parser'  => 2.44,
        'YAML'         => 1.15,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Brocade-BSC-*' },
);
