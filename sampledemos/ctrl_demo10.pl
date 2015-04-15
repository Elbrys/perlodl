#!/usr/bin/perl

use Getopt::Long;
use BVC::Controller;
use BVC::NetconfNode;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

print ("\n<<< Creating Controller instance\n");
my $bvc = new BVC::Controller($configfile);
print $bvc->dump;

print "<<< Show NETCONF nodes configured on the controller.\n";
my $result = $bvc->get_all_nodes_in_config();

if ($result) {
    print "Nodes configured: ", scalar @$result, "\n";
    foreach (@$result) {
	print "    $_\n";
    }
} else {
    print "XXX 1 Error --\n";
}

print "<<< Creating new NETCONF node\n";
my $ncNode = new BVC::NetconfNode($configfile);
print $ncNode->dump;

print "<<< Add '", $ncNode->{name}, "' NETCONF node to the controller.\n";
$result = $bvc->add_netconf_node($ncNode);

print "<<< Show NETCONF nodes configured on the controller.\n";
my $result = $bvc->get_all_nodes_in_config();

if ($result) {
    print "Nodes configured: ", scalar @$result, "\n";
    foreach (@$result) {
	print "    $_\n";
    }
} else {
    print "XXX 2 Error --\n";
}


