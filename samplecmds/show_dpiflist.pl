#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new BVC::Controller($configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600($configfile, ctrl=>$bvc);

print "<<< 'Controller': " . $bvc->{ipAddr} . ", '"
    . $vRouter->{name} . "': " . $vRouter->{ipAddr} . "\n";
my ($status, $iflist) = $vRouter->get_dataplane_interfaces_list();

if ($status == $BVC_OK) {
    print "Dataplane interfaces:\n";
    print JSON->new->canonical->pretty->encode($iflist);
}
else {
    die "Error: " . $bvc->status_string($status) . "\n";
}
