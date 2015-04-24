package BVC::NetconfNode;

# XXX EXPORT *

use strict;

use YAML;

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
    bless $self;
}

sub TO_JSON {
    my $b_obj = B::svref_2object( $_[0] );
    return    $b_obj->isa('B::HV') ? { %{ $_[0] } }
            : $b_obj->isa('B::AV') ? [ @{ $_[0] } ]
            : undef
            ;
}

sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

1;
