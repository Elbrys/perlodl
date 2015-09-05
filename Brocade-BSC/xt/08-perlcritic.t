#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Spec;
use English qw(-no_match_vars);

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
all_critic_ok();
