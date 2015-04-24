package BVC::Controller;
$BVC::VERSION = '0.01';

# XXX perldoc
# XXX EXPORT *

use strict;

use YAML;
use LWP;
use HTTP::Status qw(:constants :is status_message);  # XXX need?
use JSON;
use XML::Parser;
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
            $errmsg += " " . $http_resp->code . " - " . $http_resp->message
    }
    return $errmsg;
}

sub new {
    my $caller = shift;
    my $cfgfile = shift;

    my $yamlcfg;
    if ($cfgfile) {
        if ( -e $cfgfile ) {
            $yamlcfg = YAML::LoadFile($cfgfile);
        } else {
            unshift @_, $cfgfile;
        }
    }
    my $self = {
        ipAddr => '127.0.0.1',
        portNum => '8181',
        adminName => 'admin',
        adminPassword => 'admin',
        timeout => 5,
        @_
    };
    if ($yamlcfg) {
        $self->{ipAddr} = $yamlcfg->{ctrlIpAddr};
        $self->{portNum} = $yamlcfg->{ctrlPortNum};
        $self->{adminName} = $yamlcfg->{ctrlUname};
        $self->{adminPassword} = $yamlcfg->{ctrlPswd};
    }
    bless $self;
}    

sub _http_req {
    my $self = shift;
    my ($method, $urlpath, $data, $headerref) = @_;
    my %headers = $headerref ? %$headerref : ();

    my $url = "http://$$self{ipAddr}:$$self{portNum}$urlpath";
    my $ua = LWP::UserAgent->new;
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

sub TO_JSON {
    my $b_obj = B::svref_2object( $_[0] );
    return    $b_obj->isa('B::HV') ? { %{ $_[0] } }
            : $b_obj->isa('B::AV') ? [ @{ $_[0] } ]
            : undef
            ;
}

sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

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
                    push @nodeNames, $_->{'id'};
                }
                $status = $BVC_OK;
            }
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    return ($status, \@nodeNames);
}

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
    return ($status, $node_info);
}

sub check_node_config_status {
    my $self = shift;
    my $node = shift;

    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/$node";
    my $resp = $self->_http_req('GET', $urlpath);
    return ($resp->code == HTTP_OK)
        ? $BVC_NODE_CONFIGURED : $BVC_NODE_NOT_FOUND;
}

sub check_node_conn_status {
    my $self = shift;
    my $node = shift;

    my ($status, $nodeStatus) = $self->get_all_nodes_conn_status();
    if ($status == $BVC_OK) {
        foreach (@$nodeStatus) {
            if ($_->{'id'} eq $node) {
                return $_->{'connected'} ? $BVC_NODE_CONNECTED
                                         : $BVC_NODE_DISCONNECTED;
            }
        }
        return $BVC_NODE_NOT_FOUND;
    }
    return $BVC_UNKNOWN;
}

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
                    push @nodeNames, $_->{'id'};
                }
                $status = $BVC_OK;
            }
        }
        else {
            $status = $BVC_DATA_NOT_FOUND;
        }
    }
    return ($status, \@nodeNames);
}

sub get_all_nodes_conn_status {
    my $self = shift;
    my @nodeStatus = ();
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{'nodes'}->{'node'};
            if (! $nodes) {
                $status = $BVC_DATA_NOT_FOUND;
            }
            else {
                foreach (@$nodes) {
                    my $connected = $_->{"netconf-node-inventory:connected"};
                    if ($connected) {
                        push @nodeStatus, {'id' => $_->{'id'},
                                           'connected' => 1}
                    } else {
                        push @nodeStatus, {'id' => $_->{'id'},
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
    return ($status, \@nodeStatus);
}

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
    return ($status, $schemas);
}

sub get_schema {
    my $self = shift;
    my ($node, $schemaId, $schemaVersion) = @_;

    my $urlpath = "/restconf/operations/opendaylight-inventory:nodes/node/$node/yang-ext:mount/ietf-netconf-monitoring:get-schema";
    my $payload = '{"input": {"identifier":"' . $schemaId . '","version":"' . $schemaVersion . '","format":"yang"}}';
    my %headers = ('content-type'=>'application/yang.data+json',
                   'accept'=>'text/json, text/html, application/xml, */*');
    my $resp = $self->_http_req('POST', $urlpath, $payload, \%headers);
    if ($resp->code == HTTP_OK) {
        my $xmlp = new XML::Parser(Style => 'Tree');
        my @foo = $xmlp->parse($resp->content);
        print "0 is ", $foo[0][0], "\n";
        print "1 is ", Dumper($foo[0][1][0]), "\n";
        print "2 is ", Dumper($foo[0][1][1]), "\n";
        print "3 is ", Dumper($foo[0][1][2][0]), "\n";
        print "4 is ", Dumper($foo[0][1][2][1]), "\n";
        print "5 is ", Dumper($foo[0][1][2][2][0]), "\n";
        print "6 is ", Dumper($foo[0][1][2][2][1]), "\n";
        print "dat> ", Dumper($foo[0][1][2][2][2]), "\n\n";
#        print "<<<<<<<\n\n", Dumper(@foo), "\n\n>>>>>>>\n\n";
    }
#   XXX status check and massage
    return $resp->is_success ?  $resp->content : '';
}

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
    return ($status, $operations);
}

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
    return ($status, $modules);
}

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
    return ($status, $module);
}

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
    return ($status, $sessions);
}

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
    return ($status, $streams);
}

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
    return ($status, $service);
}

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
    return ($status, $service);
}

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
          <password xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{adminPass}</password>
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

sub delete_netconf_node {
    my $self = shift;
    my $node = shift;
    my $status = $BVC_UNKNOWN;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules/module/odl-sal-netconf-connector-cfg:sal-netconf-connector/" . $node->{name};

    my $resp = $self->_http_req('DELETE', $urlpath);
    $status = $resp->is_success ? $BVC_OK : $BVC_HTTP_ERROR;
    return ($status, $resp);
}

sub modify_netconf_node_in_config {
    my $self = shift;
    my $node = shift;
}

# get_ext_mount_config_url
# get_ext_mount_operational_url
# get_node_operational_url
# get_node_config_url

sub get_openflow_nodes_operational_list {
    my $self = shift;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";
    my $resp = $self->_http_req('GET', $urlpath);
#   XXX status check and massage
    return $resp->is_success ? $resp->content : '';
}

1;
