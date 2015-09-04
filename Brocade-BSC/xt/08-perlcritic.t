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

# my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => 'xt/perlcriticrc' );
all_critic_ok();
