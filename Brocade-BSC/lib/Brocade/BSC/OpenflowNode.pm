=head1 NAME

Brocade::BSC::OpenflowNode

=head1 DESCRIPTION

A I<Brocade::BSC::OpenflowNode> object is used to model, query, and configure
openflow devices via Brocade's OpenDaylight-based Software-Defined Networking
controller.

=cut

package Brocade::BSC::OpenflowNode;

use strict;
use warnings;

use YAML;
use JSON -convert_blessed_universally;

=head1 METHODS

=cut

# Constructor ==========================================================
#
=over 4

=item B<new>

Creates a new I<Brocade::BSC::OpenflowNode> object and populates fields with
values from argument hash, if present, or YAML configuration file.

  ### parameters:
  #   + cfgfile       - path to YAML configuration file specifying node attributes
  #   + ctrl          - reference to Brocade::BSC controller object (required)
  #   + name          - name of controlled openflow node
  #
  ### YAML configuration file labels and default values
  #
  #   parameter hash | YAML label  | default value
  #   -------------- | ----------- | -------------
  #   name           | nodeName    |

Returns new I<Brocade::BSC::NetconfNode> object.
=cut
sub new {
    my $class = shift;
    my %params = @_;

    my $yamlcfg = undef;
    if ($params{cfgfile} && ( -e $params{cfgfile})) {
        $yamlcfg = YAML::LoadFile($params{cfgfile});
    }
    my $self = {
        ctrl => '',
        name => ''
    };
    if ($yamlcfg) {
        $yamlcfg->{nodeName}
            && ($self->{name} = $yamlcfg->{nodeName});
    }
    map { $params{$_} && ($self->{$_} = $params{$_}) }
        qw(ctrl name);
    bless ($self, $class);
}

# Method ===============================================================
#
=item B<as_json>

  # Returns   : Returns pretty-printed JSON string representing openflow node.

=cut
sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

# Module ===============================================================
1;

=back

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
