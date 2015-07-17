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

print ("<<< Show operational state of all configuration modules on the Controller\n");
my ($status, $result) = $bvc->get_all_modules_operational_state();

$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Modules:\n";
print JSON->new->canonical->pretty->encode($result);

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");

