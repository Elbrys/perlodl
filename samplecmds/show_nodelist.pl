#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::NetconfNode;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new BVC::Controller($configfile);


my ($status, $nodelist_ref) = $bvc->get_nodes_operational_list();
if ($status == $BVC_OK) {
    print "Nodes:\n";
    foreach (@$nodelist_ref) {
        print "    '$_'\n";
    }
    print "\n";
}
else {
    die "Error: " . $bvc->status_string($status) . "\n";
}
