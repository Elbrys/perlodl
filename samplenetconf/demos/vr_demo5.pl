#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile = "";
my $status = undef;
my @iflist;
my $ifcfg = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600(cfgfile => $configfile,
                                                ctrl=>$bvc);

print "<<< 'Controller': $bvc->{ipAddr}, '"
    . "$vRouter->{name}': $vRouter->{ipAddr}\n\n";


$status = $bvc->add_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' added to the Controller\n\n";
sleep(2);


$status = $bvc->check_node_conn_status($vRouter->{name});
$status->connected or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' is connected to the Controller\n\n";


($status, @iflist) = $vRouter->get_dataplane_interfaces_list();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Dataplane interfaces:\n";
print JSON->new->pretty->encode(\@iflist) . "\n\n";


my $sample_if = 'dp0p192p1';
print "<<< Show '$sample_if' dataplane interface configuration on the "
    . "'$vRouter->{name}'\n";
($status, $ifcfg) = $vRouter->get_dataplane_interface_cfg($sample_if);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Dataplane interface '$sample_if' config:\n";
print JSON->new->canonical->pretty->encode(JSON::decode_json($ifcfg));


print "<<< Show configuration of dataplane interfaces on the "
    . "'$vRouter->{name}'\n";
($status, $ifcfg) = $vRouter->get_dataplane_interfaces_cfg();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Dataplane interfaces config:\n";
print JSON->new->canonical->pretty->encode($ifcfg);


print ">>> Remove '$vRouter->{name}' NETCONF node from the Controller\n";
$status = $bvc->delete_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "'$vRouter->{name}' NETCONF node was successfully removed from the Controller\n\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
