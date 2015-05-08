#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;
use BVC::Netconf::Vrouter::Firewall;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $fwcfg = undef;
my $http_resp = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

my $bvc = new BVC::Controller($configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600($configfile, ctrl=>$bvc);

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


show_firewalls_cfg();


my $fw_group = "FW-ACCEPT-SRC-172_22_17_108";
print "<<< Create new firewall instance '" . $fw_group . "' on '"
    . $vRouter->{name} . "'\n\n";
my $firewall = new BVC::Netconf::Vrouter::Firewall;
$firewall->add_group($fw_group);
$firewall->add_rule($fw_group, 33,
                    'action' => 'accept',
                    'src_addr' => '172.22.17.108');
$status = $vRouter->create_firewall_instance($firewall);
if ($status == $BVC_OK) {
    print "Firewall instance '" . $fw_group . "' was successfully created\n\n";
}
else {
    die "Demo terminated: " . $bvc->status_string($status) . "\n";
}


print "<<< Show content of the firewall instance '"
    . $fw_group . "' on '" . $vRouter->{name} . "'\n";
($status, $fwcfg) = $vRouter->get_firewall_instance_cfg($fw_group);
if ($status == $BVC_OK) {
    print "Firewall instance '" . $fw_group . "':\n";
    print JSON->new->canonical->pretty->encode(JSON::decode_json($fwcfg)) . "\n\n";
}
else {
    die "Demo terminated: " . $bvc->status_string($status) . "\n";
}


show_firewalls_cfg();


print "<<< Remove firewall instance '"
    . $fw_group . "' on '" . $vRouter->{name} . "'\n";
$status = $vRouter->delete_firewall_instance($firewall);
($status == $BVC_OK)
    && print "Firewall instance '" . $fw_group . "' was successfully deleted\n\n"
    || die "Demo terminated: " . $bvc->status_string($status) . "\n";


show_firewalls_cfg();


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");


sub show_firewalls_cfg {
    print "<<< Show firewalls configuration of the '" . $vRouter->{name} . "'\n\n";
    ($status, $fwcfg) = $vRouter->get_firewalls_cfg();
    if ($status == $BVC_OK) {
        print "'" . $vRouter->{name} . "' firewalls config:\n";
        print JSON->new->canonical->pretty->encode(JSON::decode_json($fwcfg)) . "\n";
    }
    else {
        die "Demo terminated: " . $bvc->status_string($status) . "\n";
    }
}

