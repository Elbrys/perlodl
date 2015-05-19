#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600(cfgfile => $configfile,
                                                ctrl => $bvc);
print "<<< 'Controller': $bvc->{ipAddr}, " .
    "'$vRouter->{name}': $vRouter->{ipAddr}\n";

my ($status, $loopback_list) = $vRouter->get_loopback_interfaces_list();
$status->ok or die "Error: ${\$status->msg}\n";

print "Loopback interfaces config:\n";
print JSON->new->canonical->pretty->encode($loopback_list);
