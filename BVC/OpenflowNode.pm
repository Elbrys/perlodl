package BVC::OpenflowNode;

use strict;
use warnings;

use YAML;
use JSON -convert_blessed_universally;

sub new {
    my $class = shift;
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
    bless ($self, $class);
}

sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

1;
