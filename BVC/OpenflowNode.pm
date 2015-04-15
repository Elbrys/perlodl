package BVC::OpenflowNode;

# XXX EXPORT *

use strict;

use YAML;
use Data::Dumper;  # XXX remove

sub new {
    my $caller = shift;
    my $cfgfile = shift;

    my $yamlcfg;
    if ($cfgfile) {
        if ( -e $cfgfile ) {
            $yamlcfg = YAML::LoadFile($cfgfile);
        } else {
            unshift @_, $cfgfile;
        }
    }
    my $self = {
        ctrl => '',
        name => '',
        @_
    };
    if ($yamlcfg) {
        $self->{'name'} = $yamlcfg->{'nodeName'};
    }
    bless $self;
}

# XXX remove, replace with json dumping
sub dump {
    return Dumper(shift());
}

1;
