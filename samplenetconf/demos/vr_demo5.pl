#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my @iflist;
my $ifcfg = undef;
my $http_resp = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600(cfgfile => $configfile,
                                                ctrl=>$bvc);

print "<<< 'Controller': " . $bvc->{ipAddr} . ", '"
    . $vRouter->{name} . "': " . $vRouter->{ipAddr} . "\n\n";


($status, $http_resp) = $bvc->add_netconf_node($vRouter);
($status == $BVC_OK)
    && print "<<< '" . $vRouter->{name} . "' added to the Controller\n\n"
    || die "Demo terminated: " . $bvc->status_string($status) . "\n";


$status = $bvc->check_node_conn_status($vRouter->{name});
($status == $BVC_NODE_CONNECTED)
    && print "<<< '" . $vRouter->{name} . "' is connected to the Controller\n\n"
    || die "Demo terminated: " . $bvc->status_string($status) . "\n";


($status, @iflist) = $vRouter->get_dataplane_interfaces_list();
if ($status == $BVC_OK) {
    print "Dataplane interfaces:\n";
    print JSON->new->pretty->encode(\@iflist) . "\n\n";
    # foreach my $interface (@iflist) {
    #     print $interface. "\n";
    # }
    # print "\n";
}
else {
    die "Demo terminated: " . $bvc->status_string($status) . "\n";
}


my $sample_if = 'dp0p192p1';
print "<<< Show '" . $sample_if . "' dataplane interface configuration on the '"
    . $vRouter->{name} . "'\n";
($status, $ifcfg) = $vRouter->get_dataplane_interface_cfg($sample_if);
if ($status == $BVC_OK) {
    print "Dataplane interface '" . $sample_if . "' config:\n";
    print JSON->new->canonical->pretty->encode(JSON::decode_json($ifcfg));
}
else {
    die "Demo terminated: " . $bvc->status_string($status) . "\n";
}


print "<<< Show configuration of dataplane interfaces on the '"
    . $vRouter->{name} . "'\n";
($status, $ifcfg) = $vRouter->get_dataplane_interfaces_cfg();
if ($status == $BVC_OK) {
    print "Dataplane interfaces config:\n";
    print JSON->new->canonical->pretty->encode($ifcfg);
}
else {
    die "Demo terminated: " . $bvc->status_string($status) . "\n";
}


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
