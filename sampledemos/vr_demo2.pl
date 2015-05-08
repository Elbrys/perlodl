#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $schema = undef;
my $http_resp = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

my $bvc = new BVC::Controller($configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600($configfile, ctrl=>$bvc);

print "<<< 'Controller': " . $bvc->{ipAddr} . ", '"
    . $vRouter->{name} . "': " . $vRouter->{ipAddr} . "\n";

($status, $http_resp) = $bvc->add_netconf_node($vRouter);
($status == $BVC_OK)
    && print "<<< '" . $vRouter->{name} . "' added to the Controller\n\n"
    || die "Demo terminated: " . $bvc->status_string($status, $http_resp) . "\n";

$status = $bvc->check_node_conn_status($vRouter->{name});
($status == $BVC_NODE_CONNECTED)
    && print "<<< '" . $vRouter->{name} . "' is connected to the Controller\n\n"
    || die "Demo terminated: " . $bvc->status_string($status) . "\n";

my $yangModelName    = "vyatta-security-firewall";
my $yangModelVersion = "2014-11-07";
print "<<< Retrieve '" . $yangModelName
    . "' YANG model definition from the '" . $vRouter->{name} . "'\n\n";

($status, $schema) = $vRouter->get_schema($yangModelName, $yangModelVersion);
if ($status == $BVC_OK) {
    print "YANG model definition:\n";
#    print JSON->new->canonical->pretty->encode($schema);
    print $schema;
}
else {
    die "Demo terminated: " . $bvc->status_string($status) . "\n";
}

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");



