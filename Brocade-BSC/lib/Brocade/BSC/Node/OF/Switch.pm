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

=head1 NAME

Brocade::BSC::Node::OF::Switch

=head1 DESCRIPTION

Query and configure an OpenFlow-capable switch connected to
a BSC controller.

=cut

package Brocade::BSC::Node::OF::Switch;

use strict;
use warnings;

use parent qw(Brocade::BSC::Node::OF);
use Brocade::BSC;
use Brocade::BSC::Status qw(:constants);
use Brocade::BSC::Node::OF::FlowEntry;

use Regexp::Common;   # balanced paren matching
use HTTP::Status qw(:constants :is status_message);
use JSON -convert_blessed_universally;

=head1 METHODS

=cut

# Constructor ==========================================================
#
=over 4

=item B<new>

Creates a new I<::OFSwitch> object and populates fields with values
from argument hash, if present, or YAML configuration file.

=cut ===================================================================
sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    return $self;
}

# Method ===============================================================

=item B<get_switch_info>

  # Returns   : BSC::Status
  #           : hash ref with basic info on openflow switch

=cut ===================================================================
sub get_switch_info {
    my $self = shift;
    my $status = Brocade::BSC::Status->new;
    my %node_info = ();

    my $urlpath = $self->_oper_urlpath;
    my $resp = $self->ctrl_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        map {
            $resp->content =~ /\"flow-node-inventory:$_\":\"([^"]*)\"/
                && ($node_info{$_} = $1);
        } qw(manufacturer serial-number software hardware description);
        $status->_code($BSC_OK);
    }
    else {
        $status->_http_err($resp);
    }
    return ($status, \%node_info);
}


# Method ===============================================================

=item B<get_features_info>

  # Returns   : BSC::Status
  #           : hash ref of 'switch-features'

=cut ===================================================================
sub get_features_info {
    my $self = shift;
    my $status = Brocade::BSC::Status->new;
    my $feature_info_ref = undef;

    my $urlpath = $self->_oper_urlpath;
    my $resp = $self->ctrl_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        my $features = undef;
        ($resp->content =~ /\"flow-node-inventory:switch-features\":(\{[^\}]+\}),/)
            && (($features = $1) =~ s/flow-node-inventory:flow-feature-capability-//g);
        $feature_info_ref = decode_json($features);
        $status->_code($BSC_OK);
    }
    else {
        $status->_http_err($resp);
    }
    return ($status, $feature_info_ref);
}


# Method ===============================================================

=item B<get_ports_list>

  # Returns   : BSC::Status
  #           : array ref - list of port numbers

=cut ===================================================================
sub get_ports_list {
    my $self = shift;
    my $status = Brocade::BSC::Status->new;
    my @port_list = ();

    my $urlpath = $self->_oper_urlpath;
    my $resp = $self->ctrl_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        my $node_connector_json = ($resp->content =~ /$RE{balanced}{-keep}{-begin => "\"node-connector\":\["}{-end => "]"}/ && $1);
        @port_list = ($node_connector_json =~ /\"flow-node-inventory:port-number\":\"([0-9a-zA-Z]+)\"/g);
        $status->_code($BSC_OK);
    }
    else {
        $status->_http_err($resp);
    }
    return ($status, \@port_list);
}


# Method ===============================================================
#             get_port_brief_info
# Parameters: portnum
# Returns   :
#
# sub get_port_brief_info {
#     my $self = shift;
#     my $portnum = shift;
#     my $status = Brocade::BSC::Status->new;

#     die "XXX";
# }


# Method ===============================================================

=item B<get_ports_brief_info>

  # Returns   : BSC::Status
  #           : array ref - port info hashes

=cut ===================================================================
sub get_ports_brief_info {
    my $self = shift;
    my $status = Brocade::BSC::Status->new;
    my @ports_info = ();

    my $urlpath = $self->_oper_urlpath;
    my $resp = $self->ctrl_req('GET', $urlpath);
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
        $status->_code($BSC_OK);
    }
    else {
        $status->_http_err($resp);
    }
    return ($status, \@ports_info);
}


# Method ===============================================================

=item B<get_port_detail_info>

  # Parameters: port number
  # Returns   : BSC::Status
  #           : hash ref - port details

=cut ===================================================================
sub get_port_detail_info {
    my $self = shift;
    my $portnum = shift;
    my $status = Brocade::BSC::Status->new;
    my $port_info_ref;

    my $urlpath = $self->_oper_urlpath
        . "/node-connector/$self->{name}:$portnum";
    my $resp = $self->ctrl_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        my $node_connector = decode_json($resp->content);
        if (ref($node_connector->{'node-connector'}[0]) eq "HASH") {
            ($port_info_ref = $node_connector->{'node-connector'}[0]);
            $status->_code($BSC_OK);
        }
        else {
            $status->_code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->_http_err($resp);
    }
    return ($status, $port_info_ref);
}


# Method ===============================================================

=item B<add_modify_flow>

  # Parameters: flow_entry
  # Returns   : BSC::Status - success of operation

=cut ===================================================================
sub add_modify_flow {
    my ($self, $flow_entry) = @_;
    my $status = Brocade::BSC::Status->new($BSC_OK);

    if($flow_entry->isa("Brocade::BSC::Node::OF::FlowEntry")) {
        my %headers = ('content-type' => 'application/yang.data+json');
        my $payload = $flow_entry->get_payload();
        my $urlpath = $self->_config_urlpath
            . "/table/" . $flow_entry->table_id()
            . "/flow/" . $flow_entry->id();
        my $resp = $self->ctrl_req('PUT', $urlpath, $payload, \%headers);

        ($resp->code == HTTP_OK) or $status->_http_err($resp);
    }
    else {
        $status->_code($BSC_MALFORMED_DATA);
    }
    return $status;
}


# Method ===============================================================

=item B<delete_flow>

  # Parameters: table_id
  #           : flow_id
  # Returns   : BSC::Status - success of operation

=cut ===================================================================
sub delete_flow {
    my ($self, $table_id, $flow_id) = @_;
    my $status = Brocade::BSC::Status->new($BSC_OK);

    my $urlpath = $self->_config_urlpath
        . "/table/$table_id/flow/$flow_id";
    my $resp = $self->ctrl_req('DELETE', $urlpath);
    $resp->code == HTTP_OK or $status->_http_err($resp);
    return $status;
}


# Method ===============================================================

=item B<delete_flows>

  # Parameters: table_id - to be cleared of all flows
  # Returns   : BSC::Status - success of operation

=cut ===================================================================
sub delete_flows {
    my ($self, $table_id) = @_;

    my ($status, $flow_entries) = $self->get_configured_FlowEntries($table_id);
    if ($status->ok) {
        foreach (@$flow_entries) {
            $self->delete_flow($table_id, $_->id);
        }
    }
    return $status;
}

# Method ===============================================================

=item B<get_configured_flow>

  # Parameters: flow table_id
  #           : flow_id
  # Returns   : BSC::Status
  #           : flow as JSON string

=cut ===================================================================
sub get_configured_flow {
    my ($self, $table_id, $flow_id) = @_;
    my $status = Brocade::BSC::Status->new;
    my $flow = undef;

    my $urlpath = $self->_config_urlpath
        . "/table/$table_id/flow/$flow_id";
    my $resp = $self->ctrl_req('GET', $urlpath);

    if (HTTP_OK == $resp->code) {
        $flow = $resp->content;
        $status->_code($BSC_OK);
    }
    else {
        $status->_http_err($resp);
    }
    return ($status, $flow);
}

# Method ===============================================================
#
#=item B<_get_flows>
#
#  # Parameters: table_id
#  #           : operational: boolean (1 => oper, 0 => config)
#  # Returns   : BSC::Status
#  #           : ref to flows from table
#
#=cut ===================================================================
sub _get_flows {
    my ($self, $table_id, $operational) = @_;
    $operational //= 1;
    my $status = Brocade::BSC::Status->new;
    my $flows = undef;

    my $urlpath = $operational
        ? $self->_oper_urlpath
        : $self->_config_urlpath;
    $urlpath .= "/flow-node-inventory:table/$table_id";

    my $resp = $self->ctrl_req('GET', $urlpath);
    if (HTTP_OK == $resp->code) {
        # XXX at least pretend to sanity check structure/existence
        $flows = decode_json($resp->content)->{'flow-node-inventory:table'}[0]->{flow};
        $status->_code( defined $flows ? $BSC_OK : $BSC_DATA_NOT_FOUND );
    }
    else {
        $status->_http_err($resp);
    }
    return ($status, $flows);
}

# Method ===============================================================
#
#=item B<_get_FlowEntries>
#
#  # Parameters: table_id
#  #           : operational: boolean (1 => oper, 0 => config)
#  # Returns   : array ref - ::Node::OF::FlowEntry objects
#
#=cut ===================================================================
sub _get_FlowEntries {
    my ($self, $table_id, $operational) = @_;
    $operational //= 1;
    my @FlowEntries = ();

    my ($status, $flows) = $self->_get_flows($table_id, $operational);
    if ($status->ok) {
        foreach (@$flows) {
            my $flowentry = Brocade::BSC::Node::OF::FlowEntry->new(href => $_);
            push @FlowEntries, $flowentry;
        }
    }
    return ($status, \@FlowEntries);
}

# Method ===============================================================

=item B<get_operational_FlowEntries>

  # Parameters: table_id  - select table to retrieve
  # Returns   : array ref - operational FlowEntry objects

=cut ===================================================================
sub get_operational_FlowEntries {
    my ($self, $table_id) = @_;
    return $self->_get_FlowEntries($table_id, 1);
}

# Method ===============================================================

=item B<get_configured_FlowEntries>

  # Parameters: table_id  - select table to retrieve
  # Returns   : array ref - configured FlowEntry objects

=cut ===================================================================
sub get_configured_FlowEntries {
    my ($self, $table_id) = @_;
    return $self->_get_FlowEntries($table_id, 0);
}

# Method ===============================================================

=item B<get_configured_FlowEntry>

  # Parameters: table_id
  #           : flow_id
  # Returns   : BSC::Status
  #           : FlowEntry object for specified table and flow

=cut ===================================================================
sub get_configured_FlowEntry {
    my ($self, $table_id, $flow_id) = @_;
    my $flowentry = undef;

    my ($status, $flow_json) = $self->get_configured_flow($table_id, $flow_id);
    if ($status->ok) {
        # XXX sanity check structure/existence
        my $flow = decode_json($flow_json)->{'flow-node-inventory:flow'}[0];
        $flowentry = Brocade::BSC::Node::OF::FlowEntry->new(href => $flow);
    }
    return ($status, $flowentry);
}


# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
