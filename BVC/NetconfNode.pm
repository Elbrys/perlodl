package BVC::NetconfNode;

# XXX EXPORT *

use strict;

use YAML;
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
	ctrl => '',
	name => '',
	ipAddr => '',
	portNum => '',
	tcpOnly => '',
	adminName => 'admin',
	adminPass => 'admin',
	@_
    };
    if ($yamlcfg) {
	$self->{'name'} = $yamlcfg->{'nodeName'};
	$self->{'ipAddr'} = $yamlcfg->{'nodeIpAddr'};
	$self->{'portNum'} = $yamlcfg->{'nodePortNum'};
	$self->{'adminName'} = $yamlcfg->{'nodeUname'};
	$self->{'adminPass'} = $yamlcfg->{'nodePswd'};
    }
    bless $self;
}

# XXX remove, replace with json dumping
sub dump {
    return Dumper(shift());
}

1;
