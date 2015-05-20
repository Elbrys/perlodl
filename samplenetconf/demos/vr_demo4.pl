#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;
use BVC::Netconf::Vrouter::Firewall;

my $configfile = "";
my $status = undef;
my $fwcfg = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

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


show_firewalls_cfg($vRouter);


my $fw_group = "FW-ACCEPT-SRC-172_22_17_108";
print "<<< Create new firewall instance '$fw_group' on ' $vRouter->{name}'\n\n";
my $firewall = new BVC::Netconf::Vrouter::Firewall;
$firewall->add_group($fw_group);
$firewall->add_rule($fw_group, 33,
                    'action' => 'accept',
                    'src_addr' => '172.22.17.108');
$status = $vRouter->create_firewall_instance($firewall);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Firewall instance '$fw_group' was successfully created\n\n";


print "<<< Show content of the firewall instance "
    . "'$fw_group' on '$vRouter->{name}'\n";
($status, $fwcfg) = $vRouter->get_firewall_instance_cfg($fw_group);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Firewall instance '" . $fw_group . "':\n";
print JSON->new->canonical->pretty->encode(JSON::decode_json($fwcfg)) . "\n\n";


show_firewalls_cfg($vRouter);


print "<<< Remove firewall instance '$fw_group' on '$vRouter->{name}'\n";
$status = $vRouter->delete_firewall_instance($firewall);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Firewall instance '$fw_group' was successfully deleted\n\n";


show_firewalls_cfg($vRouter);


print ">>> Remove '$vRouter->{name}' NETCONF node from the Controller\n";
$status = $bvc->delete_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "'$vRouter->{name}' NETCONF node was successfully removed from the Controller\n\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");


sub show_firewalls_cfg {
    my $vRouter = shift;

    print "<<< Show firewalls configuration of the '$vRouter->{name}'\n\n";
    ($status, $fwcfg) = $vRouter->get_firewalls_cfg();
    $status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

    print "'$vRouter->{name}' firewalls config:\n";
    print JSON->new->canonical->pretty->encode(JSON::decode_json($fwcfg)) . "\n";
}

