#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Openflow::OFSwitch;

my $configfile = "";
my $status = undef;
my $portlist = undef;
my $portinfo = undef;

my $sample = "openflow:1";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
print "'Controller':\n";
print $bvc->as_json() . "\n";
my $ofswitch = new Brocade::BSC::Openflow::OFSwitch(ctrl => $bvc, name => $sample);


print "<<< Get detailed information about ports on OpenFlow node '$sample'\n";
($status, $portlist) = $ofswitch->get_ports_list();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

foreach my $port (@$portlist) {
    ($status, $portinfo) = $ofswitch->get_port_detail_info($port);
    $status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

    print "Port '$port' info:\n";
    print JSON->new->pretty->encode($portinfo) . "\n";
}


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
