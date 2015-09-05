#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Find;
use File::Spec;
use English qw(-no_match_vars);

my $Test = Test::Builder->new;

my @files = _perl_files();
$Test->plan (tests => scalar @files);

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan skip_all => $msg;
}

if ($^V lt 'v5.20.0') {
    plan skip_all => 'perlcritic only run on most recent perl in matrix';
}

my $rcfile = File::Spec->catfile ('xt', 'perlcriticrc');
Test::Perl::Critic->import ( -profile => $rcfile );

foreach my $file (@files) {
    critic_ok ($file);
}


# subroutine: find all perl files of interest for this test

sub _perl_files {
    my @files;
    # lib/.../*.pm
    File::Find::find({
        wanted => sub { my ($vol, $path, $file) = File::Spec->splitpath($_);
                        -f $_ &&
                            $file =~ /.*\.pm$/ &&
                            push @files, $_; },
        no_chdir => 1,
        },
        'lib');
    # t/b##-*.t t/s##-*.t
    File::Find::find({
        wanted => sub { my ($vol, $path, $file) = File::Spec->splitpath($_);
                        -f $_ &&
                            $file =~ /^[bs][0-9][0-9]-.*\.t$/ &&
                            push @files, $_; },
        no_chdir => 1,
        },
        '.');
    # ../.../*.pl
    File::Find::find({
        wanted => sub { my ($vol, $path, $file) = File::Spec->splitpath($_);
                        -f $_ &&
                            $file =~ /.*\.pl$/ &&
                            push @files, $_; },
        no_chdir => 1,
        },
        '..');

    return @files;
}
