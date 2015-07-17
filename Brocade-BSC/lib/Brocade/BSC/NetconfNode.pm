=head1 Brocade::BSC::NetconfNode

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

package Brocade::BSC::NetconfNode;

use strict;
use warnings;

use YAML;
use JSON -convert_blessed_universally;

# Constructor ==========================================================
# Parameters: cfgfile : name of YAML file for configuring object (opt)
#             explicit values override config overrides defaults
#
#             object hash   | YAML label
#             ------------- | ----------
#             ctrl          | ----------   ref to controller object (required)
#             name          | nodeName
#             ipAddr        | nodeIpAddr   IP address of controller
#             portNum       | nodePortNum  TCP port of node NETCONF interface
#             tcpOnly       | ----------   boolean
#             adminName     | nodeUname    username
#             adminPassword | nodePswd     password
# Returns   : Brocade::BSC::NetconfNode object
# 
sub new {
    my $class = shift;
    my %params = @_;

    my $yamlcfg;
    if ($params{cfgfile} && ( -e $params{cfgfile})) {
        $yamlcfg = YAML::LoadFile($params{cfgfile});
    }
    my $self = {
        ctrl          => $params{ctrl},
        name          => '',
        ipAddr        => '',
        portNum       => 830,
        tcpOnly       => 0,
        adminName     => 'admin',
        adminPassword => 'admin'
    };
    if ($yamlcfg) {
        $yamlcfg->{nodeName}
            && ($self->{name} = $yamlcfg->{nodeName});
        $yamlcfg->{nodeIpAddr}
            && ($self->{ipAddr} = $yamlcfg->{nodeIpAddr});
        $yamlcfg->{nodePortNum}
            && ($self->{portNum} = $yamlcfg->{nodePortNum});
        $yamlcfg->{nodeUname}
            && ($self->{adminName} = $yamlcfg->{nodeUname});
        $yamlcfg->{nodePswd}
            && ($self->{adminPassword} = $yamlcfg->{nodePswd});
    }
    map { $params{$_} && ($self->{$_} = $params{$_}) }
        qw(name ipAddr portNum tcpOnly adminName adminPassword);
    bless ($self, $class);
}

# Method ===============================================================
# as_json
# Parameters: none
# Returns   : Brocade::BSC::OpenflowNode as formatted JSON string
#
sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

1;
