package BVC::Controller;
$BVC::VERSION = '0.01';

# XXX perldoc
# XXX EXPORT *

use strict;

use YAML;
use LWP;
use JSON;
use Data::Dumper;  # XXX remove

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
	username => 'admin',
	password => 'admin',
	timeout => 5,
	@_
    };
    if ($yamlcfg) {
	$self->{'ipAddr'} = $yamlcfg->{'ctrlIpAddr'};
	$self->{'portNum'} = $yamlcfg->{'ctrlPortNum'};
	$self->{'username'} = $yamlcfg->{'ctrlUname'};
	$self->{'password'} = $yamlcfg->{'ctrlPswd'};
    }
    bless $self;
}    

sub http_get {
    my $self = shift;
    my ($urlpath, $data, %headers) = @_;

    my $url = "http://$$self{ipAddr}:$$self{portNum}$urlpath";
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $url);
    $req->authorization_basic($$self{username}, $$self{password});
    return $ua->request($req);
}

sub http_post {
#YYY+
    print @_;
    print "\n\n";
#YYY-
    my $self = shift;
    my ($urlpath, $data, %headers) = @_;

    my $url = "http://$$self{ipAddr}:$$self{portNum}$urlpath";
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(POST => $url);
    while (my($header, $value) = each %headers) {
	$req->header($header => $value);
    }
    $req->content($data);
    $req->authorization_basic($$self{username}, $$self{password});
#YYY+
    print "\n\n\n";
    print "url is ... $url\n";
    print "data is ... $data\n";
    print Dumper(%headers);
    print Dumper($req);
    print "\n\n\n";
#YYY-
    return $ua->request($req);
}

sub http_put {
    my $self = shift;
    my ($urlpath, $data, %headers) = @_;

    my $url = "http://$$self{ipAddr}:$$self{portNum}$urlpath";
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(PUT => $url);
    while (my($header, $value) = each %headers) {
	$req->header($header => $value);
    }
    $req->content($data);
    $req->authorization_basic($$self{username}, $$self{password});
    return $ua->request($req);
}

# XXX remove, replace with json dumping
sub dump {
    return Dumper(shift());
}

sub get_nodes_operational_list {
    my $self = shift;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

sub get_node_info {
    my $self = shift;
    my $node = shift;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/$node";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content
}

sub check_node_config_status {
    my $self = shift;
    my $node = shift;

    my $urlpath = "/restconf/config/opendaylight-inventory:nodes";
    my $resp = $self->http_get($urlpath);
#   XXX status check
    return $resp->content;
}

sub check_node_conn_status {
    my $self = shift;
    my $node = shift;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return 1;
}

sub get_all_nodes_in_config {
    my $self = shift;
    my @nodeNames = [];

    my $urlpath = "/restconf/config/opendaylight-inventory:nodes";
    my $resp = $self->http_get($urlpath);
#   XXX status check
    my $nodes = from_json($resp->content)->{'nodes'}->{'node'};
    foreach (@$nodes) {
#	print $_->{'id'}, "\n";
	push @nodeNames, $_->{'id'};
    }
    return \@nodeNames;
#    return $resp->content;
}

sub get_all_nodes_conn_status {
    my $self = shift;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

sub get_schemas {
    my $self = shift;
    my $node = shift;
    my $status = 42;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/$node/yang-ext:mount/ietf-netconf-monitoring:netconf-state/schemas";
    my $resp = $self->http_get($urlpath);
#   XXX status check
    return ($status, $resp->content);
#   return $resp->is_success ? $resp->content : '';
}

sub get_schema {
    my $self = shift;
    my ($node, $schemaId, $schemaVersion) = @_;
    my $status = 0;

    my $urlpath = "/restconf/operations/opendaylight-inventory:nodes/node/$node/yang-ext:mount/ietf-netconf-monitoring:get-schema";
    my $payload = "{\"input\": {\"identifier\":\"$schemaId\",\"version\":\"$schemaVersion\",\"format\":\"yang\"}}";
    my %headers = {'content-type'=>'applications/yang.data+json',
		   'accept'=>'text/json, text/html, application/xml, */*'};
    my $resp = $self->http_post($urlpath, $payload, \%headers);
#   XXX status check and massage
    return $status, $resp->content;    
}

sub get_netconf_operations {
    my $self = shift;
    my $node = shift;

    my $urlpath = "/restconf/operations/opendaylight-inventory:nodes/node/$node/yang-ext:mount/";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

sub get_all_modules_operational_state {
    my $self = shift;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules";
    my $resp = $self->http_get($urlpath);
    # BVC returns bad JSON on this REST call.  Sanitize.
    my $json = $resp->content;
    $json =~ s/\\\n//g;
#   XXX status check and massage
    return $json;
}

sub get_module_operational_state {
    my $self = shift;
    my ($moduleType, $moduleName) = @_;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules/module/$moduleType/$moduleName";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

sub get_sessions_info {
    my $self = shift;
    my $node = shift;

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/$node/yang-ext:mount/ietf-netconf-monitoring:netconf-state/sessions";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

sub get_streams_info {
    my $self = shift;

    my $urlpath = "/restconf/streams";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

sub get_service_providers_info {
    my $self = shift;

    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:services";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

sub get_service_provider_info {
    my $self = shift;
    my $name = shift;

    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:services/service/$name";
    my $resp = $self->http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

sub add_netconf_node {
    my $self = shift;
    my $node = shift;
}

sub delete_netconf_node {
    my $self = shift;
    my $node = shift;
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
    my $resp = http_get($urlpath);
#   XXX status check and massage
    return $resp->content;
}

1;
