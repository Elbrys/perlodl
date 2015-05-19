#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Openflow::OFSwitch;

my $configfile = "";
my $status = undef;
my $switch_info = undef;
my $features = undef;
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

    
print "<<< Get information about OpenFlow node '$sample'\n";
($status, $switch_info) = $ofswitch->get_switch_info();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Node '$sample' generic info:\n";
print JSON->new->canonical->pretty->encode($switch_info) . "\n";


($status, $features) = $ofswitch->get_features_info();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Node '$sample' features:\n";
print JSON->new->canonical->pretty->encode($features) . "\n";


($status, $portlist) = $ofswitch->get_ports_list();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Node '$sample' ports list:\n";
print JSON->new->canonical->pretty->encode($portlist) . "\n";


($status, $portinfo) = $ofswitch->get_ports_brief_info();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Node '$sample' ports brief information:\n";
print JSON->new->canonical->pretty->encode($portinfo);


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
