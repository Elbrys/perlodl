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

my ($status, $node_info) = $bvc->get_node_info($ncNode->{name});
$status->ok or die "Error: ${\$status->msg}\n";

print JSON->new->canonical->pretty->encode($node_info);
