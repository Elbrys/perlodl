=head1 BVC::Openflow::FlowEntry

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

package BVC::Openflow::FlowEntry;

use strict;
use warnings;

use Data::Walk;
use JSON -convert_blessed_universally;


#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
package Instruction;

sub new {
    my $class = shift;

    my $self = {
        apply_actions => {},
        order => 0,
        @_
    };
    bless ($self, $class);
}

sub apply_actions {
    my $self = shift;
    my $action_ref = shift;

    if (not exists ($self->{apply_actions}->{action})) {
        $self->{apply_actions}->{action} = [];
    }
    $action_ref and push $self->{apply_actions}->{action}, $action_ref;
    return $self->{apply_actions};
}

#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
package BVC::Openflow::FlowEntry;

# Constructor ==========================================================
# Parameters: none
# Returns   : BVC::Openflow::FlowEntry object
# 
sub new {
    my $class = shift;
    my $self = {
        id => undef,
        cookie => undef,
        cookie_mask => undef,
        table_id => 0,
        priority => undef,
        idle_timeout => 0,
        hard_timeout => 0,
        strict => 0,
        out_port => undef,
        out_group => undef,
        flags => undef,
        flow_name => undef,
        installHw => 0,
        barrier => 0,
        buffer_id => undef,
        match => {},
        instructions => {}
    };
    bless ($self, $class);
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
        . JSON->new->canonical->allow_blessed->convert_blessed->encode($clone)
        . q(});
    $payload =~ s/_/-/g;
    $payload =~ s/table-id/table_id/g;
    $payload =~ s/cookie-mask/cookie_mask/g;

    return $payload;
}


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
    $self->{instructions}->{instruction} = $instruction;
}


sub add_match {
    my $self = shift;
    my $match_ref = shift;

    $self->{match} = $match_ref;
}


# Module ===============================================================
1;
