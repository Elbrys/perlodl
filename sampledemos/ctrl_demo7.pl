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

print ("<<< Show operational state of a particular configuration module on the controller.\n");
my $moduleType = "opendaylight-rest-connector:rest-connector-impl";
my $moduleName = "rest-connector-default-impl";
print "    (module type: $moduleType,\n     module name: $moduleName)\n";
my $result = $bvc->get_module_operational_state($moduleType, $moduleName);

if ($result) {
    print "Module:\n";
    my $json = new JSON->allow_nonref->canonical;
    print $json->pretty->encode($json->decode($result));
} else {
    print "XXX Error --\n";
}
