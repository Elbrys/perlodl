#!/usr/bin/perl

use Getopt::Long;
use BVC::Controller;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

print ("\n<<< Creating Controller instance\n");
my $bvc = new BVC::Controller($configfile);
print $bvc->dump;

print ("<<< Get list of service provider applications available on the Controller.\n");
my $result = $bvc->get_service_providers_info();
if ($result) {
    print "Service providers:\n";
    my $json = new JSON->allow_nonref->canonical;
    print $json->pretty->encode($json->decode($result));
} else {
    print "XXX Error --\n";
}
