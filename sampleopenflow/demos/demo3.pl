#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Openflow::OFSwitch;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $portlist = undef;
my $portinfo = undef;

my $sample = "openflow:1";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
print "'Controller':\n";
print $bvc->as_json() . "\n";
my $ofswitch = new BVC::Openflow::OFSwitch(ctrl => $bvc, name => $sample);


print "<<< Get detailed information about ports on OpenFlow node '" . $sample . "'\n";
($status, $portlist) = $ofswitch->get_ports_list();
($BVC_OK == $status)
    || die "!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n";

foreach my $port (@$portlist) {
    ($status, $portinfo) = $ofswitch->get_port_detail_info($port);
    if ($BVC_OK == $status) {
        print "Port '$port' info:\n";
        print JSON->new->pretty->encode($portinfo) . "\n";
    }
    else {
        die "!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n";
    }
}


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
