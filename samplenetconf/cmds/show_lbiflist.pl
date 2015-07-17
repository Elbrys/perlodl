#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Netconf::Vrouter::VR5600;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $vRouter = new Brocade::BSC::Netconf::Vrouter::VR5600(cfgfile => $configfile,
                                                         ctrl => $bvc);
print "<<< 'Controller': $bvc->{ipAddr}, " .
    "'$vRouter->{name}': $vRouter->{ipAddr}\n";

my ($status, $loopback_list) = $vRouter->get_loopback_interfaces_list();
$status->ok or die "Error: ${\$status->msg}\n";

print "Loopback interfaces config:\n";
print JSON->new->canonical->pretty->encode($loopback_list);
