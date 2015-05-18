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

my ($status, $config) = $vRouter->get_cfg();
if ($status == $BVC_OK) {
    print "'" . $vRouter->{name} . "' configuration:\n";
    print JSON->new->canonical->pretty->encode($config);
}
else {
    die "Error: " . $bvc->status_string($status) . "\n";
}
