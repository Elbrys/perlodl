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

my $name = "opendaylight-md-sal-binding:binding-data-broker";
print ("<<< Get '$name' service provider info.\n");
my $result = $bvc->get_service_provider_info($name);
if ($result) {
    print "Service provider:\n";
    my $json = new JSON->allow_nonref->canonical;
    print $json->pretty->encode($json->decode($result));
} else {
    print "XXX Error --\n";
}
