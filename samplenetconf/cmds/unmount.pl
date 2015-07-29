#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Node::NC;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $ncNode = new Brocade::BSC::Node::NC(cfgfile => $configfile, ctrl => $bvc);

my ($status, $http_resp) = $bvc->delete_netconf_node($ncNode);
$status->ok or die "Error: ${\$status->msg}\n";

print "'$ncNode->{name}' was successfully removed from the Controller\n\n";


