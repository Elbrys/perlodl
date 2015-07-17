=head1 Brocade::BSC::Openflow::FlowEntry

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

package Brocade::BSC::Openflow::FlowEntry;

use strict;
use warnings;

use Brocade::BSC::Openflow::Match;

use Data::Walk;
use JSON -convert_blessed_universally;


# Package ==============================================================
# Instruction
#    simplify serializing Brocade::BSC::Openflow::FlowEntry
#
# ======================================================================
package Instruction;

use Carp::Assert;

sub new {
    my ($class, %params) = @_;

    my $order = $params{order} ? $params{order} : 0;
    my $self = {
        apply_actions => {},
        order => $order,
    };
    bless ($self, $class);
    if ($params{aref}) {
        # XXX 
        my $apply_action_href = ${$params{aref}}[0];
        assert (ref($apply_action_href) eq "HASH");
        assert (exists ($apply_action_href->{'apply-actions'}));
        assert (exists ($apply_action_href->{'apply-actions'}->{action}));
        my $action_aref = $apply_action_href->{'apply-actions'}->{action};
        assert (ref($action_aref) eq "ARRAY");
        foreach my $action (@$action_aref) {
            if (exists $action->{'drop-action'}) {
                my $new_action = new Brocade::BSC::Openflow::Action::Drop;
                $self->apply_actions($new_action);
            }
            elsif (exists $action->{'output-action'}) {
                my $new_action = new Brocade::BSC::Openflow::Action::Output(href => $action->{'output-action'});
                $self->apply_actions($new_action);
            }
            elsif (exists $action->{'set-field'}) {
                my $new_action = new Brocade::BSC::Openflow::Action::SetField(href => $action->{'set-field'});
                $self->apply_actions($new_action);
            }
            elsif (exists $action->{'push-vlan-action'}) {
                my $new_action = new Brocade::BSC::Openflow::Action::PushVlanHeader(href => $action->{'push-vlan-action'});
                $self->apply_actions($new_action);
            }
            elsif (exists $action->{'pop-vlan-action'}) {
                my $new_action = new Brocade::BSC::Openflow::Action::PopVlanHeader(href => $action->{'pop-vlan-action'});
                $self->apply_actions($new_action);
            }
            elsif (exists $action->{'push-mpls-action'}) {
                my $new_action = new Brocade::BSC::Openflow::Action::PushMplsHeader(href => $action->{'push-mpls-action'});
                $self->apply_actions($new_action);
            }
            elsif (exists $action->{'pop-mpls-action'}) {
                my $new_action = new Brocade::BSC::Openflow::Action::PopMplsHeader(href => $action->{'pop-mpls-action'});
                $self->apply_actions($new_action);
            }
        }
    }
    return $self;
}

sub apply_actions {
    my $self = shift;
    my $action_ref = shift;

    if (not exists ($self->{apply_actions}->{action})) {
        $self->{apply_actions}->{action} = [];
    }
    $action_ref and push @{$self->{apply_actions}->{action}}, $action_ref;
    return $self->{apply_actions};
}


# Package ==============================================================
# Instructions
#    simplify serializing Brocade::BSC::Openflow::FlowEntry
#
# ======================================================================
package Instructions;

sub new {
    my ($class, %params) = @_;

    my $self = {
        instruction => []
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            if ($key eq 'instruction') {
                $self->instruction(new Instruction(aref => $value))
            }
        }
    }
    return $self;
}


# Method ===============================================================
#             accessor
# Parameters: none for get; new instruction for set
# Returns   : array: instructions
#
sub instruction {
    my ($self, $instruction) = @_;

    defined $self->{instruction} or $self->instruction = new Instruction;
    (2 == @_) and push @{$self->{instruction}}, $instruction;
    return $self->{instruction};
}

# Package ==============================================================
# Brocade::BSC::Openflow::FlowEntry
#
#
# ======================================================================
package Brocade::BSC::Openflow::FlowEntry;

# Constructor ==========================================================
# Parameters: none
# Returns   : Brocade::BSC::Openflow::FlowEntry object
# 
sub new {
    my ($class, %params) = @_;
    my $self = {
        id => undef,
        cookie => undef,
        cookie_mask => undef,
        table_id => 0,
        priority => undef,
        idle_timeout => 0,
        hard_timeout => 0,
        strict => undef,
        out_port => undef,
        out_group => undef,
        flags => undef,
        flow_name => undef,
        installHw => undef,
        barrier => undef,
        buffer_id => undef,
        match => {},
        instructions => undef
    };
    $self->{instructions} = new Instructions;
    bless ($self, $class);
    # if ($params{json}) {
    #     die "foobar\n";
    # }
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            if ($key eq 'match') {
                $self->add_match(new Brocade::BSC::Openflow::Match(href => $value));
            }
            elsif ($key eq 'instructions') {
                $self->{instructions} = new Instructions(href => $value);
            }
            else {
                $self->{$key} = $value;
            }
        }
    }
    return $self;
}

# Method ===============================================================
#             as_json
# Parameters: none
# Returns   : FlowEntry as formatted JSON string
#
sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}


# Subroutine ===========================================================
#             _strip_undef: remove all keys with undefined value from hash
# Parameters: none.  use as arg to Data::Walk::walk
# Returns   : irrelevant
#
sub _strip_undef {
    if ("HASH" eq ref) {
        while (my ($key, $value) = each %$_) {
            defined $value or delete $_->{$key};
        }
    }
}

# Method ===============================================================
#             get_payload
# Parameters: none
# Returns   : FlowEntry as formatted for transmission to controller
#
sub get_payload {
    my $self = shift;

    # hack clone
    my $clone = decode_json($self->as_json());
    Data::Walk::walk(\&_strip_undef, $clone);

    my $payload = q({"flow-node-inventory:flow":)
        . JSON->new->canonical->encode($clone)
        . q(});
    $payload =~ s/_/-/g;
    $payload =~ s/table-id/table_id/g;
    $payload =~ s/cookie-mask/cookie_mask/g;

    return $payload;
}


# Method ===============================================================
#             as_oxm
# Parameters: none
# Returns   : FlowEntry as formatted for transmission to controller
#
no strict 'refs';
sub as_oxm {
    my $self = shift;

    my $oxm = "";
    #              accessor      => format
    my @xlate = (['cookie'       => 'cookie=0x%x'],
#                 ['duration'     => 'duration=%ds'],
                 ['table_id'     => 'table=%d'],
#                 ['pkts_cnt'     => 'n_packets=%d'],
#                 ['bytes_cnt'    => 'n_bytes=%d'],
                 ['idle_timeout' => 'idle_timeout=%d'],
                 ['hard_timeout' => 'hard_timeout=%d'],
                 ['priority'     => 'priority=%d']
        );
    foreach (@xlate) {
        my ($value, $format) = ($_->[0]($self), $_->[1]);
        if (defined $value) {
            $oxm .= q(,) if length ($oxm);
            $oxm .= sprintf ($format, $value);
        }
    }
    if (defined $self->{match}) {
        $oxm .= " matchs={" . $self->{match}->as_oxm . "}";
    }
    if (defined $self->{instructions}) {
        $oxm .= " actions={";
        foreach my $instr (@{$self->{instructions}->{instruction}}) {
            my $action_ct = 0;
            foreach my $action (@{$instr->{apply_actions}->{action}}) {
                $action_ct++ and $oxm .= q(,);
                $oxm .= $action->as_oxm();
                print ref $action . "  <<<\n";
            }
        }
        $oxm .= "}";
    }
    return $oxm;
}
use strict 'refs';


# Method ===============================================================
#             accessors
# Parameters: none for gets; value to set for sets
# Returns   : FlowEntry value
#
sub table_id {
    my ($self, $table_id) = @_;
    $self->{table_id} = (2 == @_) ? $table_id : $self->{table_id};
}
sub flow_name {
    my ($self, $flow_name) = @_;
    $self->{flow_name} = (2 == @_) ? $flow_name : $self->{flow_name};
}
sub id {
    my ($self, $id) = @_;
    $self->{id} = (2 == @_) ? $id : $self->{id};
}
sub install_hw {
    my ($self, $install_hw) = @_;
    $self->{installHw} = (2 == @_) ? $install_hw : $self->{installHw};
}
sub priority {
    my ($self, $priority) = @_;
    $self->{priority} = (2 == @_) ? $priority : $self->{priority};
}
sub hard_timeout {
    my ($self, $timeout) = @_;
    $self->{hard_timeout} = (2 == @_) ? $timeout : $self->{hard_timeout};
}
sub idle_timeout {
    my ($self, $timeout) = @_;
    $self->{idle_timeout} = (2 == @_) ? $timeout : $self->{idle_timeout};
}
sub cookie {
    my ($self, $cookie) = @_;
    $self->{cookie} = (2 == @_) ? $cookie : $self->{cookie};
}
sub cookie_mask {
    my ($self, $mask) = @_;
    $self->{cookie_mask} = (2 == @_) ? $mask : $self->{cookie_mask};
}
sub strict {
    my ($self, $strict) = @_;
    $self->{strict} = (2 == @_) ? $strict : $self->{strict};
}

sub add_instruction {
    my ($self, $order) = @_;

    my $instruction = new Instruction(order => $order);
    if (not exists ($self->{instructions}->{instruction})) {
        $self->{instructions}->{instruction} = [];
    }
    push @{$self->{instructions}->{instruction}}, $instruction;
    return $instruction;
}


sub add_match {
    my $self = shift;
    my $match_ref = shift;

    $self->{match} = $match_ref;
}


# Module ===============================================================
1;
