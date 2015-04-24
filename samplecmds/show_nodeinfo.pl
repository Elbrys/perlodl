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

my ($status, $node_info) = $bvc->get_node_info($ncNode->{name});
if ($status == $BVC_OK) {
    print JSON->new->canonical->pretty->encode($node_info);
}
else {
    die "Error: " . $bvc->status_string($status) . "\n";
}
