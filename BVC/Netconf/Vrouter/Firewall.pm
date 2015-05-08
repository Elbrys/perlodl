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

package BVC::Netconf::Vrouter::Firewall;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(Firewall);

use JSON -convert_blessed_universally;

#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
package Rule;

sub new {
    my $class = shift;
    my $tagnode = shift;

    my $self = {
        'tagnode' => $tagnode,
        @_
    };
    bless ($self, $class);
}

sub add_action {
    my $self = shift;
    my $action = shift;

    $self->{action} = $action;
}

sub get_name {
    my $self = shift;

    return $self->{tagnode};
}

#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
package Group;

sub new {
    my $class = shift;
    my $tagnode = shift;

    my $self = {
        tagnode => $tagnode,
        rule => []
    };
    bless ($self, $class);
}

sub get_name {
    my $self = shift;
    return $self->{tagnode};
}



#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
package BVC::Netconf::Vrouter::Firewall;

sub new {
    my $class = shift;
    my $self = {
        name => []
    };
    bless ($self, $class);
}

sub as_json {
    my $self = shift;

    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

sub add_group {
    my $self = shift;
    my $name = shift;

    my $group = new Group($name);
    push $self->{name}, $group;
}

sub get_group {
    my $self = shift;
    my $name = shift;

    my @groups = $self->{name};
    foreach my $groupref (@{ $self->{name} }) {
        if ($groupref->{tagnode} eq $name) {
            return $groupref;
        }
    }
    return undef;
}

sub add_rule {
    my $self       = shift;
    my $group_name = shift;
    my $rule_id    = shift;

    my $rule = new Rule($rule_id, @_);
    my $group = $self->get_group($group_name);
    push $group->{rule}, $rule;
}

sub get_rule {
    my $self = shift;

    # XXX
}

sub get_rules {
    my $self = shift;

    my @rules = ();
    foreach my $rule (@{ $self->{name} }) {
        push @rules, $rule;
    }
    return @rules;
}

sub get_payload {
    my $self = shift;

    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    my $payload = '{"vyatta-security:security":{"vyatta-security-firewall:firewall":'
        . $json->encode($self)
        . '}}';
    $payload =~ s/"src_addr":"([0-9\.]*)"/"source":{"address":"$1"}/g;
    $payload =~ s/typename/type-name/g;
    return $payload;
}

sub get_url_extension {
    my $self = shift;

    return "vyatta-security:security/vyatta-security-firewall:firewall";
}

1;
