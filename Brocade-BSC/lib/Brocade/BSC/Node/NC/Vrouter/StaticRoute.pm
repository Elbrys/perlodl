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

Brocade::BSC::Node::NC::Vrouter::StaticRoute

=head1 DESCRIPTION

Create and modify static route configuration on a Vyatta virtual router
controlled by a Brocade::BSC controller.

=cut

package Brocade::BSC::Node::NC::Vrouter::StaticRoute;

use strict;
use warnings;

use parent qw(Brocade::BSC::Node);
use JSON -convert_blessed_universally;


# Constructor ==========================================================

=over 4

=item B<new>

Creates and returns a new I<Brocade::BSC::Node::NC::Vrouter::StaticRoute> object.

=cut

sub new {
    my $class = shift;

    my $self = {
        arp              => [],
        interface_route  => [],
        interface_route6 => [],
        route            => [],
        route6           => [],
        table            => [],
    };
    return bless ($self, $class);
}


# Method ===============================================================

=item B<get_payload>

  # Returns   : OpenVpn interface configuration as JSON for
                posting to controller.

=cut ===================================================================

sub get_payload {
    my $self = shift;

    my $payload =
        '{"vyatta-protocols:protocols":'
      . '{"vyatta-protocols-static:static":['
      . $self->_stripped_json . ']}}';
    $payload =~ s/_/-/g;

    return $payload;
}


# Method ===============================================================
#
# _find_interface_route
# Parameter hash:
#   create - boolean, add entry if it doesn't already exist
#   subnet - required, identifier for entry
#
# ======================================================================
sub _find_interface_route {
    my ($self, %params) = @_;
    my $route = undef;
    foreach my $rt (@{$self->{interface_route}}) {
        $route = $rt;
        last if ($route->{tagnode} eq $params{subnet});
    }
    if ($params{create} and not defined $route) {
        $route = {tagnode => $params{subnet}};
        push @{$self->{interface_route}}, $route;
    }
    return $route;
}


# Method ===============================================================
#
# _find_nh_interface
# Parameter hash:
#   create - boolean, add entry if it doesn't already exist
#   ifname - required, identifier for entry
#   route  - required, route hash to which to add this nh
#
# ======================================================================
sub _find_nh_interface {
    my %params  = @_;
    my $nexthop = undef;

    $params{ifname} or return;
    my $route = $params{route} or return;
    defined $route->{next_hop_interface}
      or $route->{next_hop_interface} = [];
    foreach my $nh (@{$route->{next_hop_interface}}) {
        $nexthop = $nh;
        last if ($nexthop->{tagnode} eq $params{ifname});
    }
    if ($params{create} and not defined $nexthop) {
        $nexthop = {tagnode => $params{ifname}};
        push @{$route->{next_hop_interface}}, $nexthop;
    }
    return $nexthop;
}


# Method ===============================================================

=item B<interface_route>

Add a static route for the specified subnet.

  # Parameter : $subnet
  # Returns   : hashref - route

=cut ===================================================================

sub interface_route {
    my ($self, $subnet) = @_;
    my $route = $self->_find_interface_route(
        create => 1,
        subnet => $subnet
    );
    return $route;
}


# Method ===============================================================

=item B<interface_route_next_hop_interface>

Specify interface on subnet containing next hop device for this route

  # Parameter hash: subnet - req; destination network
                    ifname - req; interface
                    disable - opt, bool; set to disable route
                    distance - opt, int; set metric

  # Returns   : OpenVpn interface configuration as JSON for
                posting to controller.

=cut ===================================================================

sub interface_route_next_hop_interface {
    my ($self, %params) = @_;
    my $route = $self->_find_interface_route(
        create => 1,
        subnet => $params{subnet});
    my $nhif = _find_nh_interface(
        create => 1,
        route  => $route,
        ifname => $params{ifname});
    $params{disable}  && ($nhif->{disable}  = '');
    $params{distance} && ($nhif->{distance} = $params{distance});
    return $nhif;
}


# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
