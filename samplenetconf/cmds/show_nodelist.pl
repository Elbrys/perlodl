#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::NetconfNode;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new BVC::Controller(cfgfile => $configfile);

my ($status, $nodelist_ref) = $bvc->get_nodes_operational_list();
$status->ok or die "Error: ${\$status->msg}\n";

print "Nodes:\n";
foreach (@$nodelist_ref) {
    print "    '$_'\n";
}
print "\n";
