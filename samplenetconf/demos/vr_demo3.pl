#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile = "";
my $status = undef;
my $config = undef;
my $http_resp = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600(cfgfile => $configfile,
                                                ctrl=>$bvc);

print "<<< 'Controller': $bvc->{ipAddr}, '"
    . "$vRouter->{name}': $vRouter->{ipAddr}\n\n";

($status, $http_resp) = $bvc->add_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "<<< '$vRouter->{name}' added to the Controller\n\n";

$status = $bvc->check_node_conn_status($vRouter->{name});
$status->connected or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "<<< '$vRouter->{name}' is connected to the Controller\n\n";

print "<<< Show configuration of the '" . $vRouter->{name} . "'\n";
($status, $config) = $vRouter->get_cfg();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "'$vRouter->{name}' configuration:\n";
print JSON->new->canonical->pretty->encode($config);

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");



