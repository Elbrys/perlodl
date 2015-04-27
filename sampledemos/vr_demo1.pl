#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $schemas = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

my $bvc = new BVC::Controller($configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600($configfile, ctrl=>$bvc);

print "<<< 'Controller': " . $bvc->{ipAddr} . ", '"
    . $vRouter->{name} . "': " . $vRouter->{ipAddr} . "\n";

$status = $bvc->add_netconf_node($vRouter);
($status == $BVC_OK)
    && print "<<< '" . $vRouter->{name} . "' added to the Controller\n"
    || die "Demo terminated: " . $bvc->status_string($status) . "\n";

$status = $bvc->check_node_conn_status($vRouter->{name});
($status == $BVC_NODE_CONNECTED)
    && print "<<< '" . $vRouter->{name} . "' is connected to the Controller\n"
    || die "Demo terminated: " . $bvc->status_string($status) . "\n";

print "<<< Get list of all YANG models supported by the node '"
    . $vRouter->{name} . "'\n";
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



