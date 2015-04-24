#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

print ("\n<<< Creating Controller instance\n");
my $bvc = new BVC::Controller($configfile);
print "'Controller':\n";
print $bvc->as_json() . "\n";

print ("<<< Show list of all NETCONF operations supported by the Controller\n");
my ($status, $result) = $bvc->get_netconf_operations('controller-config');

if ($status = $BVC_OK) {
    print "NETCONF operations:\n";
    print JSON->new->canonical->pretty->encode($result);
}
else {
    die "\n!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n\n";
}

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
