#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

print ("\n<<< Creating Controller instance\n");
my $bvc = new Brocade::BSC(cfgfile => $configfile);
print "'Controller':\n";
print $bvc->as_json() . "\n";

print ("<<< Show operational state of a particular configuration module on the Controller\n");
my $moduleType = "opendaylight-rest-connector:rest-connector-impl";
my $moduleName = "rest-connector-default-impl";
print "    (module type: $moduleType,\n     module name: $moduleName)\n";
my ($status, $result) =
    $bvc->get_module_operational_state($moduleType, $moduleName);

$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Module:\n";
print JSON->new->canonical->pretty->encode($result);

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");

