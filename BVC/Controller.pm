=head1 BVC::Controller

Configure and query the Brocade Vyatta Controller.

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

package BVC::Controller;
$BVC::VERSION = '0.01';

# XXX perldoc

use strict;
use warnings;

use YAML;
use LWP;
use HTTP::Status qw(:constants :is status_message);
use JSON -convert_blessed_universally;
use XML::Parser;
use Carp::Assert;
use Readonly;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($BVC_OK
                 $BVC_CONN_ERROR
                 $BVC_DATA_NOT_FOUND
                 $BVC_BAD_REQUEST
                 $BVC_UNAUTHORIZED_ACCESS
                 $BVC_INTERNAL_ERROR
                 $BVC_NODE_CONNECTED
                 $BVC_NODE_DISCONNECTED
                 $BVC_NODE_NOT_FOUND
                 $BVC_NODE_CONFIGURED
                 $BVC_HTTP_ERROR
                 $BVC_MALFORMED_DATA
                 $BVC_UNKNOWN
);

Readonly our $BVC_OK                  =>  0;
Readonly our $BVC_CONN_ERROR          =>  1;
Readonly our $BVC_DATA_NOT_FOUND      =>  2;
Readonly our $BVC_BAD_REQUEST         =>  3;
Readonly our $BVC_UNAUTHORIZED_ACCESS =>  4;
Readonly our $BVC_INTERNAL_ERROR      =>  5;
Readonly our $BVC_NODE_CONNECTED      =>  6;
Readonly our $BVC_NODE_DISCONNECTED   =>  7;
Readonly our $BVC_NODE_NOT_FOUND      =>  8;
Readonly our $BVC_NODE_CONFIGURED     =>  9;
Readonly our $BVC_HTTP_ERROR          => 10;
Readonly our $BVC_MALFORMED_DATA      => 11;
Readonly our $BVC_UNKNOWN             => 12;

sub status_string {
    my $self = shift;
    my ($status, $http_resp) = @_;

    my $errmsg = ($status == $BVC_OK)                  ? "Success"
               : ($status == $BVC_CONN_ERROR)          ? "Server connection error"
               : ($status == $BVC_DATA_NOT_FOUND)      ? "Requested data not found"
               : ($status == $BVC_BAD_REQUEST)         ? "Bad or invalid data in request"
               : ($status == $BVC_UNAUTHORIZED_ACCESS) ? "Server unauthorized access"
               : ($status == $BVC_INTERNAL_ERROR)      ? "Internal server error"
               : ($status == $BVC_NODE_CONNECTED)      ? "Node is connected"
               : ($status == $BVC_NODE_DISCONNECTED)   ? "Node is disconnected"
               : ($status == $BVC_NODE_NOT_FOUND)      ? "Node not found"
               : ($status == $BVC_NODE_CONFIGURED)     ? "Node is configured"
               : ($status == $BVC_HTTP_ERROR)          ? "HTTP error"
               : ($status == $BVC_MALFORMED_DATA)      ? "Malformed data"
               : ($status == $BVC_UNKNOWN)             ? "Unknown error"
               :                                        "Undefined status code " . $status;
    if (($status == $BVC_HTTP_ERROR)
        && $http_resp
        && $http_resp->code
        && $http_resp->message) {
            $errmsg .= " " . $http_resp->code . " - " . $http_resp->message
    }
    return $errmsg;
}

# Constructor ==========================================================
# Parameters: cfgfile : name of YAML file for configuring object (opt)
#             explicit values override config overrides defaults
#
#             object hash   | YAML label
#             ------------- | ----------
#             ipAddr        | ctrlIpAddr   IP address of controller
#             portNum       | ctrlPortNum  TCP port of ctrl REST interface
#             adminName     | ctrlUname    username
#             adminPassword | ctrlPswd     password
#             timeout       | timeout      in seconds on HTTP requests
# Returns   : BVC::Controller object
# 
sub new {
    my $caller = shift;
    my %params = @_;

    my $yamlcfg;
    if ($params{cfgfile} && ( -e $params{cfgfile})) {
        $yamlcfg = YAML::LoadFile($params{cfgfile});
    }
    my $self = {
        ipAddr        => '127.0.0.1',
        portNum       => '8181',
        adminName     => 'admin',
        adminPassword => 'admin',
        timeout       => 5
    };
    if ($yamlcfg) {
        $yamlcfg->{ctrlIpAddr}
            && ($self->{ipAddr} = $yamlcfg->{ctrlIpAddr});
        $yamlcfg->{ctrlPortNum}
            && ($self->{portNum} = $yamlcfg->{ctrlPortNum});
        $yamlcfg->{ctrlUname}
            && ($self->{adminName} = $yamlcfg->{ctrlUname});
        $yamlcfg->{ctrlPswd}
            && ($self->{adminPassword} = $yamlcfg->{ctrlPswd});
        $yamlcfg->{timeout}
            && ($self->{timeout} = $yamlcfg->{timeout});
    }
    map { $params{$_} && ($self->{$_} = $params{$_}) }
        qw(ipAddr portNum adminName adminPassword timeout);
    bless $self;
}    

# Method ===============================================================
# _http_req : semi-private; send HTTP request to BVC Controller
# Parameters: $method (string, req) HTTP verb
#           : $urlpath (string, req) path for REST request
#           : $data (string, opt)
#           : $headerref (hash ref, opt)
# Returns   : HTTP::Response
#
sub _http_req {
    my $self = shift;
    my ($method, $urlpath, $data, $headerref) = @_;
    my %headers = $headerref ? %$headerref : ();

    my $url = "http://$$self{ipAddr}:$$self{portNum}$urlpath";
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->{timeout});
    my $req = HTTP::Request->new($method => $url);
    while (my($header, $value) = each %headers) {
        $req->header($header => $value);
    }
    if ($data) {
        $req->content($data);
    }
    $req->authorization_basic($$self{adminName}, $$self{adminPassword});

    return $ua->request($req);
}

# Method ===============================================================
# as_json
# Parameters: none
# Returns   : BVC::Controller as formatted JSON string
#
sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

# Method ===============================================================
# get_nodes_operational_list
# Parameters: none
# Returns   : status code (integer)
#           : reference to array of node names
#
sub get_nodes_operational_list {
    my $self = shift;
    my @nodeNames = ();
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{nodes}->{node};
            if (! $nodes) {
                $status = $BVC_DATA_NOT_FOUND;
            }
            else {
                foreach (@$nodes) {
                    push @nodeNames, $_->{id};
                }
                $status = $BVC_OK;
            }
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, \@nodeNames);
}

# Method ===============================================================
# get_node_info 
# Parameters: node name (string)
# Returns   : status code (integer)
#           : node_info XXX
#
sub get_node_info {
    my $self = shift;
    my $node = shift;
    my $node_info = undef;
    my $status = $BVC_DATA_NOT_FOUND;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/$node";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"node\"/) {
            $node_info = decode_json($resp->content)->{node};
            $status = $node_info ? $BVC_OK : $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $node_info);
}

# Method ===============================================================
# check_node_config_status
# Parameters: 
# Returns   : 
#
sub check_node_config_status {
    my $self = shift;
    my $node = shift;

    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/$node";
    my $resp = $self->_http_req('GET', $urlpath);
    return ($resp->code == HTTP_OK)
        ? $BVC_NODE_CONFIGURED : $BVC_NODE_NOT_FOUND;
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub check_node_conn_status {
    my $self = shift;
    my $node = shift;

    my ($status, $nodeStatus) = $self->get_all_nodes_conn_status();
    if ($status == $BVC_OK) {
        foreach (@$nodeStatus) {
            if ($_->{id} eq $node) {
                return $_->{connected} ? $BVC_NODE_CONNECTED
                                       : $BVC_NODE_DISCONNECTED;
            }
        }
        return $BVC_NODE_NOT_FOUND;
    }
    return $BVC_UNKNOWN;
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_all_nodes_in_config {
    my $self = shift;
    my @nodeNames = ();
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{nodes}->{node};
            if (! $nodes) {
                $status = $BVC_DATA_NOT_FOUND;
            }
            else {
                foreach (@$nodes) {
                    push @nodeNames, $_->{id};
                }
                $status = $BVC_OK;
            }
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, \@nodeNames);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_all_nodes_conn_status {
    my $self = shift;
    my @nodeStatus = ();
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{nodes}->{node};
            if (! $nodes) {
                $status = $BVC_DATA_NOT_FOUND;
            }
            else {
                foreach (@$nodes) {
                    my $connected = $_->{"netconf-node-inventory:connected"};
                    if ($connected) {
                        push @nodeStatus, {'id' => $_->{id},
                                           'connected' => 1}
                    } else {
                        push @nodeStatus, {'id' => $_->{id},
                                           'connected' => 0}
                    }
                }
                $status = $BVC_OK;
            }
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, \@nodeStatus);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_schemas {
    my $self = shift;
    my $node = shift;
    my $schemas = undef;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/$node/yang-ext:mount/ietf-netconf-monitoring:netconf-state/schemas";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"schemas\"/) {
            $schemas = decode_json($resp->content)->{schemas}->{schema};
            $status = $schemas ? $BVC_OK : $BVC_DATA_NOT_FOUND;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $schemas);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_schema {
    my $self = shift;
    my ($node, $schemaId, $schemaVersion) = @_;
    my $status = $BVC_UNKNOWN;
    my $schema = undef;

    my $urlpath = "/restconf/operations/opendaylight-inventory:nodes/node/$node/yang-ext:mount/ietf-netconf-monitoring:get-schema";
    my $payload = '{"input": {"identifier":"' . $schemaId . '","version":"' . $schemaVersion . '","format":"yang"}}';
    my %headers = ('content-type'=>'application/yang.data+json',
                   'accept'=>'text/json, text/html, application/xml, */*');

    my $resp = $self->_http_req('POST', $urlpath, $payload, \%headers);
    if ($resp->code == HTTP_OK) {
        my $xmltree_ref = new XML::Parser(Style => 'Tree')->parse($resp->content);
        assert   ($xmltree_ref->[0]          eq 'get-schema');
        assert   ($xmltree_ref->[1][1]       eq 'output');
        assert   ($xmltree_ref->[1][2][1]    eq 'data');
        assert   ($xmltree_ref->[1][2][2][1] == 0);
        $schema = $xmltree_ref->[1][2][2][2];
        $status = $BVC_OK;
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $schema);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_netconf_operations {
    my $self = shift;
    my $node = shift;
    my $operations = undef;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/operations/opendaylight-inventory:nodes/node/$node/yang-ext:mount/";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"operations\"/) {
            $operations = decode_json($resp->content)->{operations};
            $status = $BVC_OK;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $operations);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_all_modules_operational_state {
    my $self = shift;
    my $modules = undef;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules";
    
    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"modules\"/) {
            # BVC returns bad JSON on this REST call.  Sanitize.
            my $json = $resp->content;
            $json =~ s/\\\n//g;
            $modules = decode_json($json)->{modules}->{module};
            $status = $modules ? $BVC_OK : $BVC_DATA_NOT_FOUND;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $modules);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_module_operational_state {
    my $self = shift;
    my ($moduleType, $moduleName) = @_;
    my $module = undef;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules/module/$moduleType/$moduleName";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK ) {
        if ($resp->content =~ /\"module\"/) {
            $module = decode_json($resp->content)->{module};
            $status = $module ? $BVC_OK : $BVC_DATA_NOT_FOUND;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $module);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_sessions_info {
    my $self = shift;
    my $node = shift;
    my $sessions = undef;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/$node/yang-ext:mount/ietf-netconf-monitoring:netconf-state/sessions";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"sessions\"/) {
            $sessions = decode_json($resp->content)->{sessions};
            $status = $sessions ? $BVC_OK : $BVC_DATA_NOT_FOUND;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $sessions);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_streams_info {
    my $self = shift;
    my $streams = undef;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/streams";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"streams\"/) {
            $streams = decode_json($resp->content)->{streams};
            $status = $streams ? $BVC_OK : $BVC_DATA_NOT_FOUND;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $streams);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_service_providers_info {
    my $self = shift;
    my $service = undef;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:services";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"services\"/) {
            $service = decode_json($resp->content)->{services}->{service};
            $status = $service ? $BVC_OK : $BVC_DATA_NOT_FOUND;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $service);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_service_provider_info {
    my $self = shift;
    my $name = shift;
    my $service = undef;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:services/service/$name";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"service\"/) {
            $service = decode_json($resp->content)->{service};
            $status = $BVC_OK;
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, $service);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub add_netconf_node {
    my $self = shift;
    my $node = shift;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules";
    my %headers = ('content-type' => 'application/xml',
                   'accept' => 'application/xml');
    my $xmlPayload = <<END_XML;
        <module xmlns="urn:opendaylight:params:xml:ns:yang:controller:config">
          <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">prefix:sal-netconf-connector</type>
          <name>$node->{name}</name>
          <address xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{ipAddr}</address>
          <port xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{portNum}</port>
          <username xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{adminName}</username>
          <password xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{adminPassword}</password>
          <tcp-only xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{tcpOnly}</tcp-only>
          <event-executor xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:netty">prefix:netty-event-executor</type>
            <name>global-event-executor</name>
          </event-executor>
          <binding-registry xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:md:sal:binding">prefix:binding-broker-osgi-registry</type>
            <name>binding-osgi-broker</name>
          </binding-registry>
          <dom-registry xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:md:sal:dom">prefix:dom-broker-osgi-registry</type>
            <name>dom-broker</name>
          </dom-registry>
          <client-dispatcher xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:config:netconf">prefix:netconf-client-dispatcher</type>
            <name>global-netconf-dispatcher</name>
          </client-dispatcher>
          <processing-executor xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:threadpool">prefix:threadpool</type>
            <name>global-netconf-processing-executor</name>
          </processing-executor>
        </module>
END_XML

    my $resp = $self->_http_req('POST', $urlpath, $xmlPayload, \%headers);
    $status = $resp->is_success ? $BVC_OK : $BVC_HTTP_ERROR;
    return ($status, $resp);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub delete_netconf_node {
    my $self = shift;
    my $node = shift;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules/module/odl-sal-netconf-connector-cfg:sal-netconf-connector/" . $node->{name};

    my $resp = $self->_http_req('DELETE', $urlpath);
    $status = $resp->is_success ? $BVC_OK : $BVC_HTTP_ERROR;
    return ($status, $resp);
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub modify_netconf_node_in_config {
    my $self = shift;
    my $node = shift;

    die "XXX";
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_ext_mount_config_urlpath {
    my $self = shift;
    my $node = shift;

    return "/restconf/config/opendaylight-inventory:nodes/node/"
        . $node . "/yang-ext:mount/";
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_ext_mount_operational_urlpath {
    my $self = shift;
    my $node = shift;

    return "/restconf/operational/opendaylight-inventory:nodes/node/"
        . $node . "/yang-ext:mount/";
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_node_operational_urlpath {
    my $self = shift;
    my $node = shift;

    return "/restconf/operational/opendaylight-inventory:nodes/node/" . $node;
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_node_config_urlpath {
    my $self = shift;
    my $node = shift;

    return "/restconf/config/opendaylight-inventory:nodes/node/" . $node;
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub get_openflow_nodes_operational_list {
    my $self = shift;
    my $status = $BVC_UNKNOWN;
    my @nodelist = ();

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";
    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{nodes}->{node};
            if (! $nodes) {
                $status = $BVC_DATA_NOT_FOUND;
            }
            else {
                $status = $BVC_OK;
                foreach (@$nodes) {
                    $_->{id} =~ /^(openflow:[0-9]*)/ && push @nodelist, $1;
                }
            }
        }
    }
    else {
        $status = $BVC_HTTP_ERROR;
    }
    return ($status, \@nodelist);
}

# Module ===============================================================
1;
