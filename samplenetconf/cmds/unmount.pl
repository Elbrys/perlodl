#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::NetconfNode;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $ncNode = new Brocade::BSC::NetconfNode(cfgfile => $configfile, ctrl => $bvc);

my ($status, $http_resp) = $bvc->delete_netconf_node($ncNode);
$status->ok or die "Error: ${\$status->msg}\n";

print "'$ncNode->{name}' was successfully removed from the Controller\n\n";


