#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::NetconfNode;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new Brocade::BSC(cfgfile => $configfile);

my ($status, $nodelist_ref) = $bvc->get_nodes_operational_list();
$status->ok or die "Error: ${\$status->msg}\n";

print "Nodes:\n";
foreach (@$nodelist_ref) {
    print "    '$_'\n";
}
print "\n";
