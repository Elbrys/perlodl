# Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

package BVC::Netconf::Vrouter::VR5600;

use strict;
use warnings;

use base ("BVC::NetconfNode");
use HTTP::Status qw(:constants :is status_message);
use JSON;
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

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    my $resp = $self->{ctrl}->_http_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = decode_json($resp->content);
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

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    $url .= "vyatta-security:security/vyatta-security-firewall:firewall";
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

sub get_firewall_instance_cfg {
    my $self = shift;
    my $instance = shift;
    my $status = $BVC_UNKNOWN;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
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
    return ($status, $config);
}

sub create_firewall_instance {
    my $self = shift;
    my $fwInstance = shift;
    my $status = $BVC_UNKNOWN;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    my %headers = ('content-type'=>'application/yang.data+json');
    my $payload = $fwInstance->get_payload();

    my $resp = $self->{ctrl}->_http_req('POST', $urlpath, $payload, \%headers);

    return ($resp->is_success) ? $BVC_OK : $BVC_HTTP_ERROR;
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

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . $fwInstance->get_url_extension()
        . "/name/";
    my @rules = $fwInstance->get_rules();

    foreach my $rule (@rules) {
        my $rule_url = $urlpath . $rule->get_name();
        my $resp = $self->{ctrl}->_http_req('DELETE', $rule_url);
        if ($resp->code != HTTP_OK) {
            $status = $BVC_HTTP_ERROR;
            last;
        }
        else {
            $status = $BVC_OK;
        }
    }
    return $status;
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

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    $urlpath .= "vyatta-interfaces:interfaces";

    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
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
    my $iflist = undef;
    my @dpiflist;

    ($status, $dpifcfg) = $self->get_interfaces_cfg();
    if (! $dpifcfg) {
        $status = $BVC_DATA_NOT_FOUND;
    }
    else {
        $iflist = decode_json($dpifcfg)->{interfaces}->{'vyatta-interfaces-dataplane:dataplane'};
        foreach my $interface (@$iflist) {
            push @dpiflist, $interface->{tagnode};
        }
        $status = $BVC_OK;
    }
    return ($status, @dpiflist);
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
    }
    return ($status, $dpifcfg);
}

sub get_dataplane_interface_cfg {
    my $self = shift;
    my $ifname = shift;
    my $status = $BVC_UNKNOWN;
    my $cfg = undef;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-interfaces:interfaces/vyatta-interfaces-dataplane:dataplane/"
        . $ifname;
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        $cfg = $resp->content;
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $cfg);
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
    }
    return ($status, $lbifcfg);
}

sub get_loopback_interface_cfg {
    die "XXX";
}

1;
