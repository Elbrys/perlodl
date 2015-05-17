=head1 BVC::Openflow::OFSwitch

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

package BVC::Openflow::OFSwitch;

use strict;
use warnings;

use parent qw(BVC::OpenflowNode);
use BVC::Controller;

use Regexp::Common;   # balanced paren matching
use HTTP::Status qw(:constants :is status_message);
use JSON -convert_blessed_universally;

# Constructor ==========================================================
# Parameters: cfgfile : name of YAML file for configuring object (opt)
#             explicit values override config overrides defaults
# Returns   : BVC::Openflow::OFSwitch object
# 
sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
}

# Method ===============================================================
# as_json
# Parameters: none
# Returns   : BVC::Openflow::OFSwitch as formatted JSON string
#
sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}


# Method ===============================================================
#             get_switch_info
# Parameters: none
# Returns   : hash ref with basic info on openflow switch
#
sub get_switch_info {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my %node_info = ();

    my $urlpath = $self->{ctrl}->get_node_operational_urlpath($self->{name});
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        map {
            $resp->content =~ /\"flow-node-inventory:$_\":\"([^"]*)\"/
                && ($node_info{$_} = $1);
        } qw(manufacturer serial-number software hardware description);
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, \%node_info);
}


# Method ===============================================================
#             get_features_info
# Parameters: none
# Returns   : hash ref of 'switch-features'
#
sub get_features_info {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my $feature_info_ref = undef;

    my $urlpath = $self->{ctrl}->get_node_operational_urlpath($self->{name});
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        my $features = undef;
        ($resp->content =~ /\"flow-node-inventory:switch-features\":(\{[^\}]+\}),/)
            && (($features = $1) =~ s/flow-node-inventory:flow-feature-capability-//g);
        $feature_info_ref = decode_json($features);
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $feature_info_ref);
}


# Method ===============================================================
#             get_ports_list
# Parameters: none
# Returns   : array ref with list of port numbers
#
sub get_ports_list {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my @port_list = ();

    my $urlpath = $self->{ctrl}->get_node_operational_urlpath($self->{name});
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        my $node_connector_json = ($resp->content =~ /$RE{balanced}{-keep}{-begin => "\"node-connector\":\["}{-end => "]"}/ && $1);
        @port_list = ($node_connector_json =~ /\"flow-node-inventory:port-number\":\"([0-9a-zA-Z]+)\"/g);
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, \@port_list);
}


# Method ===============================================================
#             get_port_brief_info
# Parameters: portnum
# Returns   :
#
sub get_port_brief_info {
    my $self = shift;
    my $portnum = shift;
    my $status = $BVC_UNKNOWN;

    die "XXX";
}


# Method ===============================================================
#             get_ports_brief_info
# Parameters: none
# Returns   : ref to array of port info hashes
#
sub get_ports_brief_info {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my @ports_info = ();

    my $urlpath = $self->{ctrl}->get_node_operational_urlpath($self->{name});
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        my $node_connector_json = ($resp->content =~ /$RE{balanced}{-keep}{-begin => "\"node-connector\":\["}{-end => "]"}/ && $1);
        $node_connector_json =~ s/^\"node-connector\"://;
        my $connectors = decode_json($node_connector_json);
        foreach my $connector (@$connectors) {
            my $port_info = {};
            $port_info->{id} = $connector->{id};
            $port_info->{number} =$connector->{'flow-node-inventory:port-number'};
            $port_info->{name} = $connector->{'flow-node-inventory:name'};
            $port_info->{'MAC address'} =
                $connector->{'flow-node-inventory:hardware-address'};
            $port_info->{'current feature'} =
                uc($connector->{'flow-node-inventory:current-feature'});
            push @ports_info, $port_info;
        }
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, \@ports_info);
}


# Method ===============================================================
#             get_port_detail_info
# Parameters: portnum
# Returns   : hash ref of port details
#
sub get_port_detail_info {
    my $self = shift;
    my $portnum = shift;
    my $status = $BVC_UNKNOWN;
    my $port_info_ref;

    my $urlpath = $self->{ctrl}->get_node_operational_urlpath($self->{name}) . "/node-connector/$self->{name}:$portnum";
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        my $node_connector = decode_json($resp->content);
        if (ref($node_connector->{'node-connector'}[0]) eq "HASH") {
            ($port_info_ref = $node_connector->{'node-connector'}[0]);
            $status = $BVC_OK;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $port_info_ref);
}


# Method ===============================================================
#             add_modify_flow
# Parameters: flow_entry
# Returns   : success
#
sub add_modify_flow {
    my ($self, $flow_entry) = @_;
    my $status = $BVC_UNKNOWN;

    if($flow_entry->isa("BVC::Openflow::FlowEntry")) {
        my %headers = ('content-type' => 'application/yang.data+json');
        my $payload = $flow_entry->get_payload();
        my $urlpath = $self->{ctrl}->get_node_config_urlpath($self->{name})
            . "/table/" . $flow_entry->table_id()
            . "/flow/" . $flow_entry->id();
        my $resp = $self->{ctrl}->_http_req('PUT', $urlpath, $payload, \%headers);

        $status = (HTTP_OK == $resp->code) ? $BVC_OK : $BVC_INTERNAL_ERROR;
    }
    else {
        $status = $BVC_MALFORMED_DATA;
    }
    return $status;
}


# Method ===============================================================
#             get_configured_flow
# Parameters: flow table_id, flow_id
# Returns   : flow (JSON)
#
sub get_configured_flow {
    my ($self, $table_id, $flow_id) = @_;
    my $status = $BVC_UNKNOWN;
    my $flow = undef;

    my $urlpath = $self->{ctrl}->get_node_config_urlpath($self->{name})
        . "/table/$table_id/flow/$flow_id";
    my $resp = $self->{ctrl}->_http_req('GET', $urlpath);

    if (HTTP_OK == $resp->code) {
        $flow = $resp->content;
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $flow);
}


# Module ===============================================================
1;
