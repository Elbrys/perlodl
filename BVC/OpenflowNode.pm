package BVC::OpenflowNode;

use strict;
use warnings;

use YAML;

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
