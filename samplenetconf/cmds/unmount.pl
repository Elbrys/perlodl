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

my ($status, $http_resp) = $bvc->delete_netconf_node($ncNode);
if ($status == $BVC_OK) {
    print "'".$ncNode->{name}."' was successfully removed from the Controller\n\n";
}
else {
    die "!!!Failed: " . $bvc->status_string($status, $http_resp) . "\n\n";
}


