#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::NetconfNode;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $ncNode = new BVC::NetconfNode(cfgfile => $configfile, ctrl => $bvc);

my ($status, $nodes_ref) = $bvc->get_all_nodes_in_config();
$status->ok or die "Error: ${\$status->msg}\n";

print "Nodes configured:\n";
foreach (@$nodes_ref) {
    print "    '$_'\n";
}
print "\n";
