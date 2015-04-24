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

print ("<<< Show operational state of a particular configuration module on the Controller\n");
my $moduleType = "opendaylight-rest-connector:rest-connector-impl";
my $moduleName = "rest-connector-default-impl";
print "    (module type: $moduleType,\n     module name: $moduleName)\n";
my ($status, $result) = $bvc->get_module_operational_state($moduleType, $moduleName);

if ($status == $BVC_OK) {
    print "Module:\n";
    print JSON->new->canonical->pretty->encode($result);
}
else {
    die "\n!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n\n";
}

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");

