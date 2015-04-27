package BVC::Netconf::Vrouter::VR5600;

use strict;
use warnings;

use base ("BVC::NetconfNode");
use HTTP::Status qw(:constants :is status_message);
use BVC::Controller;

sub get_schemas {
    my $self = shift;

    return $self->{ctrl}->get_schemas($self->{name});
}

sub get_schema {
    my $self = shift;
    my ($yangId, $yangVersion) = @_;

    return $self->{ctrl}->get_schema($self->{name}, $yangId, $yangVersion);
}

sub get_cfg {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_url($self->{name});
    my $resp = $self->{ctrl}->_http_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $config);
}

sub get_firewalls_cfg {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_url($self->{name});
    $url .= "vyatta-security:security/vyatta-security-firewall:firewall";
    my $resp = $self->{ctrl}->_http_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
}

sub get_firewall_instance_cfg {
    my $self = shift;
    my $instance = shift;
    my $status = $BVC_UNKNOWN;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_url($self->{name});
    $url .= "vyatta-security:security/vyatta-security-firewall:firewall/name/"
        . $instance;
    my $resp = $self->{ctrl}->_http_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
}

sub create_firewall_instance {
    my $self = shift;
    my $fwInstance = shift;
    my $status = $BVC_UNKNOWN;

    my $url = $self->{ctrl}->get_ext_mount_config_url($self->{name});
    my %headers = ('content-type'=>'application/yang.data+json');

    die "XXX";
}

sub add_firewall_instance_rule {
    die "XXX";
}

sub update_firewall_instance_rule {
    die "XXX";
}

sub delete_firewall_instance {
    my $self = shift;
    my $fwInstance = shift;
    my $status = $BVC_UNKNOWN;

    die "XXX";
}

sub set_dataplane_interface_firewall {
    die "XXX";
}

sub delete_dataplane_interface_firewall {
    die "XXX";
}

sub get_interfaces_list {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my $ifcfg = undef;
    my @iflist = ();

    ($status, $ifcfg) = $self->get_interfaces_cfg();
    if ($status == $BVC_OK) {
        if ($ifcfg =~ /interfaces/) {
            my $XXXfoo = decode_json($ifcfg)->{interfaces};
            # XXX
        }
    }
    return ($status, \@iflist);
}

sub get_interfaces_cfg {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_url($self->{name});
    $url .= "vyatta-interfaces:interfaces";

    my $resp = $self->{ctrl}->_http_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $config);
}

sub get_dataplane_interfaces_list {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my $dpifcfg = undef;
    my @iflist = ();

    ($status, $dpifcfg) = $self->get_interfaces_cfg();
    if (! $dpifcfg) {
        $status = $BVC_DATA_NOT_FOUND;
    }
    else {
        foreach (@$dpifcfg) {
            # XXX
            push @iflist, $_;
        }
        $status = $BVC_OK;
    }
    return ($status, \@iflist);
}

sub get_dataplane_interfaces_cfg {
    my $self = shift;
    my $dpifcfg = undef;

    my ($status, $config) = $self->get_interfaces_cfg();
    if ($status == $BVC_OK) {
        my $str1 = 'interfaces';
        my $str2 = 'vyatta-interfaces-dataplane:dataplane';
        if (($config =~ /$str1/) && ($config =~ /$str2/)) {
            $dpifcfg = decode_json($config)->{$str1}->{$str2};
        }
        # if (($config =~ /interfaces/) &&
        #     ($config =~ /vyatta\-interfaces\-dataplane:dataplane/)) {
        #     $dpifcfg = decode_json($config)->{interfaces}->{'vyatta-interfaces-dataplane:dataplane'};
        # }
    }
    return ($status, $dpifcfg);
}

sub get_dataplane_interface_cfg {
    die "XXX";
}

sub get_loopback_interfaces_list {
    my $self = shift;
    my @lbiflist = ();

    my ($status, $lbifcfg) = $self->get_loopback_interfaces_cfg();
    if (! $lbifcfg) {
        $status = $BVC_DATA_NOT_FOUND;
    }
    else {
        foreach (@$lbifcfg) {
            # XXX
            push @lbiflist, $_;
        }
        $status = $BVC_OK;
    }
    return ($status, \@lbiflist);
}

sub get_loopback_interfaces_cfg {
    my $self = shift;
    my $lbifcfg = undef;

    my ($status, $config) = $self->get_interfaces_cfg();
    if ($status == $BVC_OK) {
        my $str1 = 'interfaces';
        my $str2 = 'vyatta-interfaces-loopback:loopback';
        if (($config =~ /$str1/) && ($config =~ /$str2/)) {
            $lbifcfg = decode_json($config)->{$str1}->{$str2};
        }
        # if (($config =~ /interfaces/) &&
        #     ($config =~ /vyatta\-interfaces\-dataplane:dataplane/)) {
        #     $lbifcfg = decode_json($config)->{interfaces}->{'vyatta-interfaces-dataplane:dataplane'};
        # }
    }
    return ($status, $lbifcfg);
}

sub get_loopback_interface_cfg {
    die "XXX";
}

1;
