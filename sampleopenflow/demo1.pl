#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Openflow::OFSwitch;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $oflist = undef;
my $switch_info = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
print "'Controller':\n";
print $bvc->as_json() . "\n";

print "<<< Get list of OpenFlow nodes connected to the Controller\n";
($status, $oflist) = $bvc->get_openflow_nodes_operational_list();
if ($BVC_OK == $status) {
    print "OpenFlow node names (composed as \"openflow:datapathid\"):\n";
    print JSON->new->allow_nonref->pretty->encode($oflist) . "\n";
}
else {
    die "!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n";
}
    

print "<<< Get generic information about OpenFlow nodes\n";
foreach my $ofnode (@$oflist) {
    my $ofswitch = new BVC::Openflow::OFSwitch(ctrl => $bvc, name => $ofnode);
    ($status, $switch_info) = $ofswitch->get_switch_info();
    if ($BVC_OK == $status) {
        print "'" . $ofnode . "' info:\n";
        print JSON->new->canonical->pretty->encode($switch_info) . "\n";
    }
    else {
        die "!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n";
    }
}
    

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
