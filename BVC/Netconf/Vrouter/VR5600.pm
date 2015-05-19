=head1 BVC::Netconf::Vrouter::VR5600

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
contributors may be used to endorse or promote products derived from this
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

=cut

package BVC::Netconf::Vrouter::VR5600;

use strict;
use warnings;

use base qw(BVC::NetconfNode);
use HTTP::Status qw(:constants :is status_message);
use JSON;
use BVC::Controller;
use BVC::Status qw(:constants);

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_schemas {
    my $self = shift;

    return $self->{ctrl}->get_schemas($self->{name});
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_schema {
    my $self = shift;
    my ($yangId, $yangVersion) = @_;

    return $self->{ctrl}->get_schema($self->{name}, $yangId, $yangVersion);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_cfg {
    my $self = shift;
    my $status = new BVC::Status;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    my $resp = $self->{ctrl}->_http_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = decode_json($resp->content);
        $status->code($BVC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $config);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_firewalls_cfg {
    my $self = shift;
    my $status = new BVC::Status;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    $url .= "vyatta-security:security/vyatta-security-firewall:firewall";
    my $resp = $self->{ctrl}->_http_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status->code($BVC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $config);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_firewall_instance_cfg {
    my $self = shift;
    my $instance = shift;
    my $status = new BVC::Status;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    $url .= "vyatta-security:security/vyatta-security-firewall:firewall/name/"
        . $instance;
    my $resp = $self->{ctrl}->_http_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status->code($BVC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $config);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub create_firewall_instance {
    my $self = shift;
    my $fwInstance = shift;
    my $status = new BVC::Status($BVC_OK);

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    my %headers = ('content-type'=>'application/yang.data+json');
    my $payload = $fwInstance->get_payload();

    my $resp = $self->{ctrl}->_http_req('POST', $urlpath, $payload, \%headers);
    $resp->is_success or $status->http_err($resp);

    return $status;
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub add_firewall_instance_rule {
    die "XXX";
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub update_firewall_instance_rule {
    die "XXX";
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub delete_firewall_instance {
    my $self = shift;
    my $fwInstance = shift;
    my $status = new BVC::Status;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . $fwInstance->get_url_extension()
        . "/name/";
    my @rules = $fwInstance->get_rules();

    foreach my $rule (@rules) {
        my $rule_url = $urlpath . $rule->get_name();
        my $resp = $self->{ctrl}->_http_req('DELETE', $rule_url);
        if ($resp->code != HTTP_OK) {
            $status->http_err($resp);
            last;
        }
        else {
            $status->code($BVC_OK);
        }
    }
    return $status;
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub set_dataplane_interface_firewall {
    die "XXX";
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub delete_dataplane_interface_firewall {
    die "XXX";
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_interfaces_list {
    my $self = shift;
    my $status = new BVC::Status;
    my $ifcfg = undef;
    my @iflist = ();

    ($status, $ifcfg) = $self->get_interfaces_cfg();
    if ($status->ok) {
        if ($ifcfg =~ /interfaces/) {
            my $XXXfoo = decode_json($ifcfg)->{interfaces};
            # XXX
        }
    }
    return ($status, \@iflist);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_interfaces_cfg {
    my $self = shift;
    my $status = new BVC::Status;
    my $config = undef;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    $urlpath .= "vyatta-interfaces:interfaces";

    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status->code($BVC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $config);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_dataplane_interfaces_list {
    my $self = shift;
    my $status = new BVC::Status;
    my $dpifcfg = undef;
    my $iflist = undef;
    my @dpiflist;

    ($status, $dpifcfg) = $self->get_interfaces_cfg();
    if (! $dpifcfg) {
        $status->code($BVC_DATA_NOT_FOUND);
    }
    else {
        $iflist = decode_json($dpifcfg)->{interfaces}->{'vyatta-interfaces-dataplane:dataplane'};
        foreach my $interface (@$iflist) {
            push @dpiflist, $interface->{tagnode};
        }
        $status->code($BVC_OK);
    }
    return ($status, @dpiflist);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_dataplane_interfaces_cfg {
    my $self = shift;
    my $dpifcfg = undef;

    my ($status, $config) = $self->get_interfaces_cfg();
    if ($status->ok) {
        my $str1 = 'interfaces';
        my $str2 = 'vyatta-interfaces-dataplane:dataplane';
        if ($config =~ /$str2/) {
            $dpifcfg = decode_json($config)->{$str1}->{$str2};
        }
    }
    return ($status, $dpifcfg);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_dataplane_interface_cfg {
    my $self = shift;
    my $ifname = shift;
    my $status = new BVC::Status;
    my $cfg = undef;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-interfaces:interfaces/vyatta-interfaces-dataplane:dataplane/"
        . $ifname;
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        $cfg = $resp->content;
        $status->code($BVC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $cfg);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_loopback_interfaces_list {
    my $self = shift;
    my @lbiflist = ();

    my ($status, $lbifcfg) = $self->get_loopback_interfaces_cfg();
    if (! $lbifcfg) {
        $status->code($BVC_DATA_NOT_FOUND);
    }
    else {
        foreach (@$lbifcfg) {
            push @lbiflist, $_->{tagnode};
        }
        $status->code($BVC_OK);
    }
    return ($status, \@lbiflist);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_loopback_interfaces_cfg {
    my $self = shift;
    my $lbifcfg = undef;

    my ($status, $config) = $self->get_interfaces_cfg();
    if ($status->ok) {
        my $str1 = 'interfaces';
        my $str2 = 'vyatta-interfaces-loopback:loopback';
        if (($config =~ /$str1/) && ($config =~ /$str2/)) {
            $lbifcfg = decode_json($config)->{$str1}->{$str2};
        }
    }
    return ($status, $lbifcfg);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_loopback_interface_cfg {
    my $self = shift;
    my $ifName = shift;
    my $status = new BVC::Status($BVC_OK);

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-interfaces:interfaces/vyatta-interfaces-loopback:loopback/"
        . $ifName;
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    $resp->code == HTTP_OK or $status->http_err($resp);

    return ($status, $resp);
}

# Module ===============================================================
1;
