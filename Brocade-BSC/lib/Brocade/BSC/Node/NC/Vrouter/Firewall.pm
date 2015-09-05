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

Brocade::BSC::Node::NC::Vrouter::Firewall

=head1 DESCRIPTION

Create and modify firewall rules on a Vyatta virtual router controlled
by a Brocade::BSC controller.

=cut

package Brocade::BSC::Node::NC::Vrouter::Firewall;

use strict;
use warnings;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(Firewall);

use JSON -convert_blessed_universally;

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::NC::Vrouter::Firewall::Rule;

sub new {
    my ($class, $tagnode, %attributes) = @_;

    my $self = {
        'tagnode' => $tagnode,
        %attributes,
    };
    return bless ($self, $class);
}

# Method ===============================================================
#
# Parameters:
# Returns   :
#
sub add_action {
    my ($self, $action) = @_;

    return $self->{action} = $action;
}

# Method ===============================================================
#
# Parameters:
# Returns   :
#
sub get_name {
    my $self = @_;

    return $self->{tagnode};
}

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::NC::Vrouter::Firewall::Group;

sub new {
    my ($class, $tagnode) = @_;

    my $self = {
        tagnode => $tagnode,
        rule    => []};
    return bless ($self, $class);
}

# Method ===============================================================
#
# Parameters:
# Returns   :
#
sub get_name {
    my $self = @_;
    return $self->{tagnode};
}


=head1 METHODS

=over 4

=cut

# Package ===============================================================
#
package Brocade::BSC::Node::NC::Vrouter::Firewall;

# Method ===============================================================

=item B<new>

  # Returns   : empty BSC::Node::NC::Vrouter::Firewall object

=cut ===================================================================

sub new {
    my $class = @_;
    my $self = {name => []};
    return bless ($self, $class);
}

# Method ===============================================================

=item B<as_json>

  # Returns   : pretty-printed JSON string representing Firewall object.

=cut ===================================================================

sub as_json {
    my $self = @_;

    my $json = JSON->new->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

# Method ===============================================================
#
# Parameters: name of new firewall group
# Returns   : array including new group
#           :
sub _add_group {
    my ($self, $name) = @_;

    my $group = Brocade::BSC::Node::NC::Vrouter::Firewall::Group->new($name);
    push @{$self->{name}}, $group;
    return @{$self->{name}};
}

# Method ===============================================================
#
# Parameters: name of firewall group
# Returns   :
#
sub _get_group {
    my ($self, $name) = @_;

    my @groups = $self->{name};
    foreach my $groupref (@{$self->{name}}) {
        if ($groupref->{tagnode} eq $name) {
            return $groupref;
        }
    }
    return;
}

# Method ===============================================================

=item B<add_rule>

  # Parameters: name - firewall group to which to add rule
  #           : id   - for new rule
  # Returns   :

=cut ===================================================================

sub add_rule {
    my ($self, $group_name, $rule_id, %attributes) = @_;

    my $rule = Brocade::BSC::Node::NC::Vrouter::Firewall::Rule->new($rule_id,
        %attributes);
    my $group = $self->_get_group($group_name);
    push @{$group->{rule}}, $rule;
    return @{$group->{rule}};
}

# Method ===============================================================
#
# Parameters:
# Returns   :
#
#sub ___get_rule {
#    my $self = shift;
#
# XXX
#}

# Method ===============================================================
#
# Parameters:
# Returns   :
#
sub _get_rules {
    my $self = @_;

    return @{$self->{name}};
}

# Method ===============================================================

=item B<get_payload>

  # Returns   : firewall configuration formatted as JSON appropriate
  #               for POST to BSC controller.

=cut ===================================================================

sub get_payload {
    my $self = @_;

    my $json = JSON->new->canonical->allow_blessed->convert_blessed;
    my $payload =
      '{"vyatta-security:security":{"vyatta-security-firewall:firewall":'
      . $json->encode($self) . '}}';
    $payload =~ s/"src_addr":"([0-9\.]*)"/"source":{"address":"$1"}/g;
    $payload =~
s/"typename":"([a-zA-Z0-9]+)"/"icmp":{"type-name":"$1"},"protocol":"icmp"/g;
    return $payload;
}

# Method ===============================================================
#
# Parameters:
# Returns   :
#
sub _get_url_extension {
    my $self = @_;

    return "vyatta-security:security/vyatta-security-firewall:firewall";
}

# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
