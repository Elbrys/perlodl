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

my $nodeName      = "controller-config";
my $yangModelName = "flow-topology-discovery";
my $yangModelRev  = "2013-08-19";
print "<<< Retrieve '$yangModelName' YANG model definition from the Controller\n";

my ($status, $schema) = $bvc->get_schema($nodeName, $yangModelName, $yangModelRev);

$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "YANG model:\n";
print $schema;


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
