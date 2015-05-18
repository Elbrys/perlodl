=head1 BVC::Openflow::Match

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

package BVC::Openflow::Match;

use strict;
use warnings;

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package EthernetMatch;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        ethernet_type        => undef,
        ethernet_source      => undef,
        ethernet_destination => undef,
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub type {
    my ($self, $eth_type) = @_;
    (@_ == 2) and $self->{ethernet_type}->{type} = $eth_type;
    return $self->{ethernet_type};
}
sub src {
    my ($self, $eth_src) = @_;
    (@_ == 2) and $self->{ethernet_source}->{address} = $eth_src;
    return $self->{ethernet_source};
}
sub dst {
    my ($self, $eth_dst) = @_;
    (@_ == 2) and $self->{ethernet_destination}->{address} = $eth_dst;
    return $self->{ethernet_destination};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package VlanMatch;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        vlan_id => undef,
        vlan_pcp => undef,
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub vid {
    my ($self, $vid) = @_;
    if (2 == @_) {
        $self->{vlan_id}->{vlan_id} = $vid;
        $self->{vlan_id}->{vlan_id_present} = JSON::true;
    }
    return $self->{vlan_id};
}
sub pcp {
    my ($self, $pcp) = @_;
    $self->{vlan_pcp} = (2 == @_) ? $pcp : $self->{vlan_pcp};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package IcmpMatch;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        icmpv4_type => undef,
        icmpv4_code => undef,
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub type {
    my ($self, $icmp_type) = @_;
    $self->{icmpv4_type} = (2 == @_) ? $icmp_type : $self->{icmpv4_type};
}
sub code {
    my ($self, $icmp_code) = @_;
    $self->{icmpv4_code} = (2 == @_) ? $icmp_code : $self->{icmpv4_code};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package IcmpV6Match;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        icmpv6_type => undef,
        icmpv6_code => undef,
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub type {
    my ($self, $icmp6_type) = @_;
    $self->{icmpv6_type} = (2 == @_) ? $icmp6_type : $self->{icmpv6_type};
}
sub code {
    my ($self, $icmp6_code) = @_;
    $self->{icmpv6_code} = (2 == @_) ? $icmp6_code : $self->{icmpv6_code};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package IpMatch;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        ip_dscp  => undef,     # ip_hdr[1] 7:2
        ip_ecn   => undef,     # ip_hdr[1] 1:0
        ip_protocol => undef,  # ip_hdr[0] 7:4
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub dscp {
    my ($self, $dscp) = @_;
    $self->{ip_dscp} = (2 == @_) ? $dscp : $self->{ip_dscp};
}
sub ecn {
    my ($self, $ecn) = @_;
    $self->{ip_ecn} = (2 == @_) ? $ecn : $self->{ip_ecn};
}
sub proto {
    my ($self, $proto) = @_;
    $self->{ip_protocol} = (2 == @_) ? $proto : $self->{ip_protocol};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package IPv6LabelMatch;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        ipv6_flabel => undef,
        ipv6_flabel_mask => undef,
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub flabel {
    my ($self, $flabel) = @_;
    $self->{ipv6_flabel} = (2 == @_) ? $flabel : $self->{ipv6_flabel};
}
sub flabel_mask {
    my ($self, $mask) = @_;
    $self->{flabel_mask} = (2 == @_) ? $mask : $self->{flabel_mask};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package IPv6ExtHdrMatch;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        ipv6_exthdr => undef,
        ipv6_exthdr_mask => undef,
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub exthdr {
    my ($self, $exthdr) = @_;
    $self->{ipv6_exthdr} = (2 == @_) ? $exthdr : $self->{ipv6_exthdr};
}
sub exthdr_mask {
    my ($self, $mask) = @_;
    $self->{exthdr_mask} = (2 == @_) ? $mask : $self->{exthdr_mask};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Pbb;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        pbb_isid => undef,
        pbb_mask => undef,
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub isid {
    my ($self, $isid) = @_;
    $self->{pbb_isid} = (2 == @_) ? $isid : $self->{pbb_isid};
}
sub mask {
    my ($self, $mask) = @_;
    $self->{pbb_mask} = (2 == @_) ? $mask : $self->{pbb_mask};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package ProtocolMatchFields;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        mpls_label => undef,
        mpls_tc    => undef,
        mpls_bos   => undef,
        pbb        => undef,
        @_
    };
    bless ($self, $class);
}
        
# Method ===============================================================
#             accessors
sub mpls_label {
    my ($self, $mpls_label) = @_;
    $self->{mpls_label} = (2 == @_) ? $mpls_label : $self->{mpls_label};
}
sub mpls_tc {
    my ($self, $mpls_tc) = @_;
    $self->{mpls_tc} = (2 == @_) ? $mpls_tc : $self->{mpls_tc};
}
sub mpls_bos {
    my ($self, $mpls_bos) = @_;
    $self->{mpls_bos} = (2 == @_) ? $mpls_bos : $self->{mpls_bos};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Metadata;

# Constructor ==========================================================
sub new {
    my $class = shift;

    my $self = {
        metadata => undef,
        metadata_mask => undef,
        @_
    };
    bless ($self, $class);
}

# Method ===============================================================
#             accessors
sub metadata {
    my ($self, $metadata) = @_;
    $self->{metadata} = (2 == @_) ? $metadata : $self->{metadata};
}
sub metadata_mask {
    my ($self, $mask) = @_;
    $self->{metadata_mask} = (2 == @_) ? $mask : $self->{metadata_mask};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package BVC::Openflow::Match;

# Constructor ==========================================================
# Parameters: none
# Returns   : BVC::Openflow::Match object
# 
sub new {
    my $class = shift;
    my $self = {
        in_port => undef,
        in_phy_port => undef,
        ethernet_match => undef,
        ipv4_source => undef,
        ipv4_destination => undef,
        ip_match => undef,
        ipv6_source => undef,
        ipv6_destination => undef,
        ipv6_nd_target => undef,
        ipv6_nd_sll => undef,
        ipv6_nd_tll => undef,
        ipv6_label => undef,
        ipv6_ext_header => undef,
        protocol_match_fields => undef,
        udp_source_port => undef,
        udp_destination_port => undef,
        tcp_source_port => undef,
        tcp_destination_port => undef,
        sctp_source_port => undef,
        sctp_destination_port => undef,
        icmpv4_match => undef,
        icmpv6_match => undef,
        vlan_match => undef,
        arp_op => undef,
        arp_source_transport_address => undef,
        arp_target_transport_address => undef,
        arp_source_hardware_address => undef,
        arp_target_hardware_address => undef,
        tunnel => undef,
        metadata => undef
    };
    bless ($self, $class);
}


# Method ===============================================================
#             accessors
# Parameters: none for gets; value to set for sets
# Returns   : Match value
#
sub eth_type {
    my ($self, $eth_type) = @_;
    defined $self->{ethernet_match} or
        $self->{ethernet_match} = new EthernetMatch;
    $self->{ethernet_match}->type($eth_type);
}
sub eth_src {
    my ($self, $eth_src) = @_;
    defined $self->{ethernet_match} or
        $self->{ethernet_match} = new EthernetMatch;
    $self->{ethernet_match}->src($eth_src);
}
sub eth_dst {
    my ($self, $eth_dst) = @_;
    defined $self->{ethernet_match} or
        $self->{ethernet_match} = new EthernetMatch;
    $self->{ethernet_match}->dst($eth_dst);
}
sub vlan_id {
    my ($self, $vid) = @_;
    defined $self->{vlan_match} or $self->{vlan_match} = new VlanMatch;
    $self->{vlan_match}->vid($vid);
}
sub vlan_pcp {
    my ($self, $pcp) = @_;
    defined $self->{vlan_match} or $self->{vlan_match} = new VlanMatch;
    $self->{vlan_match}->pcp($pcp);
}
sub ipv4_src {
    my ($self, $ipv4_src) = @_;
    $self->{ipv4_source} = (@_ == 2) ? $ipv4_src : $self->{ipv4_source};
}
sub ipv4_dst {
    my ($self, $ipv4_dst) = @_;
    $self->{ipv4_destination}
        = (@_ == 2) ? $ipv4_dst : $self->{ipv4_destination};
}
sub ipv6_src {
    my ($self, $ipv6_src) = @_;
    $self->{ipv6_source} = (@_ == 2) ? $ipv6_src : $self->{ipv6_source};
}
sub ipv6_dst {
    my ($self, $ipv6_dst) = @_;
    $self->{ipv6_destination}
        = (@_ == 2) ? $ipv6_dst : $self->{ipv6_destination};
}
sub ipv6_flabel {
    my ($self, $ipv6_label) = @_;
    defined $self->{ipv6_label} or $self->{ipv6_label} = new IPv6LabelMatch;
    $self->{ipv6_label}->flabel($ipv6_label);
}
sub ipv6_ext_header {
    my ($self, $ipv6_ext_header) = @_;
    defined $self->{ipv6_ext_header} or
        $self->{ipv6_ext_header} = new IPv6ExtHdrMatch;
    $self->{ipv6_ext_header}->exthdr($ipv6_ext_header);
}
sub ip_dscp {
    my ($self, $dscp) = @_;
    defined $self->{ip_match} or $self->{ip_match} = new IpMatch;
    $self->{ip_match}->dscp($dscp);
}
sub ip_ecn {
    my ($self, $ecn) = @_;
    defined $self->{ip_match} or $self->{ip_match} = new IpMatch;
    $self->{ip_match}->ecn($ecn);
}
sub ip_proto {
    my ($self, $proto) = @_;
    defined $self->{ip_match} or $self->{ip_match} = new IpMatch;
    $self->{ip_match}->proto($proto);
}
sub ip_proto_version {
    die "XXX IpMatch";
}
sub udp_src_port {
    my ($self, $udp_src_port) = @_;
    $self->{udp_source_port}
        = (@_ == 2) ? $udp_src_port : $self->{udp_source_port};
}
sub udp_dst_port {
    my ($self, $udp_dst_port) = @_;
    $self->{udp_destination_port}
        = (@_ == 2) ? $udp_dst_port : $self->{udp_destination_port};
}
sub tcp_src_port {
    my ($self, $tcp_src_port) = @_;
    $self->{tcp_source_port}
        = (@_ == 2) ? $tcp_src_port : $self->{tcp_source_port};
}
sub tcp_dst_port {
    my ($self, $tcp_dst_port) = @_;
    $self->{tcp_destination_port}
        = (@_ == 2) ? $tcp_dst_port : $self->{tcp_destination_port};
}
sub sctp_src_port {
    my ($self, $sctp_src_port) = @_;
    $self->{sctp_source_port}
        = (@_ == 2) ? $sctp_src_port : $self->{sctp_source_port};
}
sub sctp_dst_port {
    my ($self, $sctp_dst_port) = @_;
    $self->{sctp_destination_port}
        = (@_ == 2) ? $sctp_dst_port : $self->{sctp_destination_port};
}
sub icmpv4_type {
    my ($self, $icmpv4_type) = @_;
    defined $self->{icmpv4_match} or $self->{icmpv4_match} = new IcmpMatch;
    $self->{icmpv4_match}->type($icmpv4_type);
}
sub icmpv4_code {
    my ($self, $icmpv4_code) = @_;
    defined $self->{icmpv4_match} or $self->{icmpv4_match} = new IcmpMatch;
    $self->{icmpv4_match}->code($icmpv4_code);
}
sub icmpv6_type {
    my ($self, $icmpv6_type) = @_;
    defined $self->{icmpv6_match} or $self->{icmpv6_match} = new IcmpV6Match;
    $self->{icmpv6_match}->type($icmpv6_type);
}
sub icmpv6_code {
    my ($self, $icmpv6_code) = @_;
    defined $self->{icmpv6_match} or $self->{icmpv6_match} = new IcmpV6Match;
    $self->{icmpv6_match}->code($icmpv6_code);
}
sub in_port {
    my ($self, $in_port) = @_;
    $self->{in_port} = (@_ == 2) ? $in_port : $self->{in_port};
}
sub in_phy_port {
    my ($self, $in_phy_port) = @_;
    $self->{in_phy_port} = (@_ == 2) ? $in_phy_port : $self->{in_phy_port};
}
sub arp_opcode {
    my ($self, $arp_opcode) = @_;
    $self->{arp_op} = (@_ == 2) ? $arp_opcode : $self->{arp_op};
}
sub arp_src_transport_address {
    my ($self, $arp_src_transport_address) = @_;
    $self->{arp_source_transport_address}
        = (@_ == 2) ? $arp_src_transport_address
                    : $self->{arp_source_transport_address};
}
sub arp_tgt_transport_address {
    my ($self, $arp_tgt_transport_address) = @_;
    $self->{arp_target_transport_address}
        = (@_ == 2) ? $arp_tgt_transport_address
                    : $self->{arp_target_transport_address};
}
sub arp_src_hw_address {
    my ($self, $arp_src_hw_address) = @_;
    $self->{arp_source_hardware_address}->{address}
        = (@_ == 2) ? $arp_src_hw_address
                    : $self->{arp_source_hardware_address}->{address};
}
sub arp_tgt_hw_address {
    my ($self, $arp_tgt_hw_address) = @_;
    $self->{arp_target_hardware_address}->{address}
        = (@_ == 2) ? $arp_tgt_hw_address
                    : $self->{arp_target_hardware_address}->{address};
}
sub mpls_label {
    my ($self, $mpls_label) = @_;
    defined $self->{protocol_match_fields} or
        $self->{protocol_match_fields} = new ProtocolMatchFields;
    $self->{protocol_match_fields}->mpls_label($mpls_label);
}
sub mpls_tc {
    my ($self, $mpls_tc) = @_;
    defined $self->{protocol_match_fields} or
        $self->{protocol_match_fields} = new ProtocolMatchFields;
    $self->{protocol_match_fields}->mpls_tc($mpls_tc);
}
sub mpls_bos {
    my ($self, $mpls_bos) = @_;
    defined $self->{protocol_match_fields} or
        $self->{protocol_match_fields} = new ProtocolMatchFields;
    $self->{protocol_match_fields}->mpls_bos($mpls_bos);
}
sub tunnel_id {
    my ($self, $tunnel_id) = @_;
    $self->{tunnel}->{tunnel_id} = (2 == @_) ? $tunnel_id :
                                               $self->{tunnel}->{tunnel_id};
}
sub metadata {
    my ($self, $metadata) = @_;
    defined $self->{metadata} or $self->{metadata} = new Metadata;
    $self->{metadata}->metadata($metadata);
}
sub metadata_mask {
    my ($self, $mask) = @_;
    defined $self->{metadata} or $self->{metadata} = new Metadata;
    $self->{metadata}->metadata_mask($mask);
}


# Module ===============================================================
1;
