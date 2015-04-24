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
print $bvc->as_json() . "\n";

my $nodeName      = "controller-config";
my $yangModelName = "flow-topology-discovery";
my $yangModelRev  = "2013-08-19";
print "<<< Retrieve '$yangModelName' YANG model definition from controller.\n";

my $result = $bvc->get_schema($nodeName, $yangModelName, $yangModelRev);

if ($result) {
#    print $result;
#    my $json = new JSON->allow_nonref->canonical;
#    print $json->pretty->encode($json->decode($result));
} else {
    print "XXX Error--\n";
}
