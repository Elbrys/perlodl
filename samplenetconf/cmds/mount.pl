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

my ($status, $http_resp) = $bvc->add_netconf_node($ncNode);
$status->ok or die "Error: ${\$status->msg}\n";
print "'$ncNode->{name}' was successfully added to the Controller\n\n";



