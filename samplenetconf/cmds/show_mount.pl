#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::NetconfNode;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new BVC::Controller($configfile);
my $ncNode = new BVC::NetconfNode($configfile, ctrl=>$bvc);

my ($status, $nodes_ref) = $bvc->get_all_nodes_in_config();
if ($status == $BVC_OK) {
    print "Nodes configured:\n";
    foreach (@$nodes_ref) {
        print "    '$_'\n";
    }
    print "\n";
}
else {
    die "\nError: " . $bvc->status_string($status) . "\n\n";
}
