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

Brocade::BSC::Node::NC::Vrouter::OvpnIf

=head1 DESCRIPTION

Create and modify OpenVpn interface configuration on a Vyatta virtual router
controlled by a Brocade::BSC controller.

=cut

package Brocade::BSC::Node::NC::Vrouter::OvpnIf;

use strict;
use warnings;

use parent qw(Brocade::BSC::Node);
use JSON -convert_blessed_universally;


# Constructor ==========================================================
#

=over 4

=item B<new>

Creates and returns a new I<Brocade::BSC::Node::NC::Vrouter::OvpnIf> object.

=cut

sub new {
    my ($class, $name) = @_;

    my $self = {
        tagnode => $name,
        #
        #         description => undef,
        #         hash => undef,          # md5, sha1, sha256, sha512
        #         disable => undef,
        #         server => undef
        #
    };
    return bless ($self, $class);
}


# Method ===============================================================

=item B<as_json>

  # Returns   : OpenVPN interface configuration as formatted JSON string.

=cut ===================================================================

sub as_json {
    my $self = @_;
    my $json = JSON->new->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}


# Method ===============================================================

=item B<get_payload>

  # Returns   : OpenVpn interface configuration as JSON for
                posting to controller.

=cut ===================================================================

sub get_payload {
    my $self = @_;

    my $payload =
        '{"vyatta-interfaces:interfaces":'
      . '{"vyatta-interfaces-openvpn:openvpn":['
      . $self->_stripped_json . ']}}';
    $payload =~ s/_/-/g;

    return $payload;
}


# Method ===============================================================

=item B<description>

Set or retrieve the description for this OpenVPN connection

=cut ===================================================================

sub description {
    my ($self, $description) = @_;
    return $self->{description} =
      (2 == @_) ? $description : $self->{description};
}


# Method ===============================================================

=item B<mode>

Set or retrieve the mode for this OpenVPN connection

=cut ===================================================================

sub mode {
    my ($self, $mode) = @_;
    return $self->{mode} = (2 == @_) ? $mode : $self->{mode};
}


# Method ===============================================================

=item B<shared_secret_key_file>

Set or retrieve the path to the pre-shared secret file for connection

=cut ===================================================================

sub shared_secret_key_file {
    my ($self, $path) = @_;
    return $self->{shared_secret_key_file} =
      (2 == @_) ? $path : $self->{shared_secret_key_file};
}


# Method ===============================================================

=item B<local_address>

Set or retrieve the local IP address for this OpenVPN connection

=cut ===================================================================

sub local_address {
    my ($self, $addr) = @_;
    return $self->{local_address} =
      (2 == @_) ? $addr : $self->{local_address};
}


# Method ===============================================================

=item B<remote_address>

Set or retrieve the remote IP address for this OpenVPN connection

=cut ===================================================================

sub remote_address {
    my ($self, $addr) = @_;
    return $self->{remote_address} =
      (2 == @_) ? $addr : $self->{remote_address};
}


# Method ===============================================================

=item B<remote_host>

Retrieve the remote_host list, or add an IP address to it

=cut ===================================================================

sub remote_host {
    my ($self, $addr) = @_;
    $self->{remote_host} = [] if not defined $self->{remote_host};
    (2 == @_) and push @{$self->{remote_host}}, $addr;
    return $self->{remote_host};
}


# Method ===============================================================

=item B<tls_role>

Set or retrieve TLS role for this OpenVPN connection

=cut ===================================================================

sub tls_role {
    my ($self, $role) = @_;
    return if (1 == @_) and not defined $self->{tls};
    $self->{tls} = {} if not defined $self->{tls};
    return $self->{tls}->{role} = (2 == @_) ? $role : $self->{tls}->{role};
}


# Method ===============================================================

=item B<tls_dh_file>

Set or retrieve path to Diffie-Helman parameters file for this OpenVPN connection

=cut ===================================================================

sub tls_dh_file {
    my ($self, $path) = @_;
    return if (1 == @_) and not defined $self->{tls};
    $self->{tls} = {} if not defined $self->{tls};
    return $self->{tls}->{dh_file} =
      (2 == @_) ? $path : $self->{tls}->{dh_file};
}


# Method ===============================================================

=item B<tls_ca_cert_file>

Set or retrieve path to CA certificate file

=cut ===================================================================

sub tls_ca_cert_file {
    my ($self, $path) = @_;
    return if (1 == @_) and not defined $self->{tls};
    $self->{tls} = {} if not defined $self->{tls};
    return $self->{tls}->{ca_cert_file} =
      (2 == @_) ? $path : $self->{tls}->{ca_cert_file};
}


# Method ===============================================================

=item B<tls_cert_file>

Set or retrieve path to certificate file for this OpenVPN connection

=cut ===================================================================

sub tls_cert_file {
    my ($self, $path) = @_;
    return if (1 == @_) and not defined $self->{tls};
    $self->{tls} = {} if not defined $self->{tls};
    return $self->{tls}->{cert_file} =
      (2 == @_) ? $path : $self->{tls}->{cert_file};
}


# Method ===============================================================

=item B<tls_crl_file>

Set or retrieve path to certificate revocation list

=cut ===================================================================

sub tls_crl_file {
    my ($self, $path) = @_;
    return if (1 == @_) and not defined $self->{tls};
    $self->{tls} = {} if not defined $self->{tls};
    return $self->{tls}->{crl_file} =
      (2 == @_) ? $path : $self->{tls}->{crl_file};
}


# Method ===============================================================

=item B<tls_key_file>

Set or retrieve path to certificate key

=cut ===================================================================

sub tls_key_file {
    my ($self, $path) = @_;
    return if (1 == @_) and not defined $self->{tls};
    $self->{tls} = {} if not defined $self->{tls};
    return $self->{tls}->{key_file} =
      (2 == @_) ? $path : $self->{tls}->{key_file};
}


# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
