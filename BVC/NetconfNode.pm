package BVC::NetconfNode;

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
        ipAddr => '',
        portNum => 830,
        tcpOnly => 0,
        adminName => 'admin',
        adminPassword => 'admin',
        @_
    };
    if ($yamlcfg) {
        $self->{name} = $yamlcfg->{nodeName};
        $self->{ipAddr} = $yamlcfg->{nodeIpAddr};
        $self->{portNum} = $yamlcfg->{nodePortNum};
        $self->{adminName} = $yamlcfg->{nodeUname};
        $self->{adminPassword} = $yamlcfg->{nodePswd};
    }
    bless ($self, $class);
}

sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

1;
