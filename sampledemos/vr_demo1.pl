#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $schemas = undef;
my $http_resp = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600(cfgfile => $configfile,
                                                ctrl=>$bvc);

print "<<< 'Controller': " . $bvc->{ipAddr} . ", '"
    . $vRouter->{name} . "': " . $vRouter->{ipAddr} . "\n\n";

($status, $http_resp) = $bvc->add_netconf_node($vRouter);
if ($status == $BVC_OK) {
    print "<<< '" . $vRouter->{name} . "' added to the Controller\n\n";
}
else {
    die "Demo terminated: " . $bvc->status_string($status, $http_resp) . "\n";
}
sleep(2);

$status = $bvc->check_node_conn_status($vRouter->{name});
if ($status == $BVC_NODE_CONNECTED) {
    print "<<< '" . $vRouter->{name} . "' is connected to the Controller\n\n";
}
else {
    die "Demo terminated: " . $bvc->status_string($status) . "\n";
}

print "<<< Get list of all YANG models supported by the node '"
    . $vRouter->{name} . "'\n\n";
($status, $schemas) = $vRouter->get_schemas();
if ($status == $BVC_OK) {
    print "YANG models list:\n";
    print JSON->new->canonical->pretty->encode($schemas);
}
else {
    die "Demo terminated: " . $bvc->status_string($status) . "\n";
}

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");



