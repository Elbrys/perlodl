# Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Node::NC::Vrouter::VR5600;
use Brocade::BSC::Node::NC::Vrouter::Firewall;

my $configfile = "";
my $status = undef;
my $fwcfg = undef;
my $ifcfg = undef;
my $http_resp = undef;

my $fw_if = "dp0p192p1";         # unused but existing interface on vRouter
my $remote_ip = "172.22.19.120"; # XXX

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $vRouter = new Brocade::BSC::Node::NC::Vrouter::VR5600(cfgfile => $configfile,
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


my $fw_name_1 = "ACCEPT-SRC-IPADDR";
print ">>> Create new firewall instance '$fw_name_1' on '$vRouter->{name}'\n";
my $fw1 = new Brocade::BSC::Node::NC::Vrouter::Firewall;
$fw1->add_group($fw_name_1);
$fw1->add_rule($fw_name_1, 30,
               'action' => 'accept',
               'src_addr' => $remote_ip);
print $fw1->as_json() . "\n";
$status = $vRouter->create_firewall_instance($fw1);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "Firewall instance '$fw_name_1' was successfully created\n\n";

my $fw_name_2 = "DROP-ICMP";
print ">>> Create new firewall instance '$fw_name_2' on '$vRouter->{name}'\n";
my $fw2 = new Brocade::BSC::Node::NC::Vrouter::Firewall;
$fw2->add_group($fw_name_2);
$fw2->add_rule($fw_name_2, 40,
               'action' => 'drop',
               'typename' => 'ping');
print $fw2->as_json() . "\n";
$status = $vRouter->create_firewall_instance($fw2);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "Firewall instance '$fw_name_2' was successfully created\n\n";


show_firewalls_cfg($vRouter);


print "<<< Apply firewall '$fw_name_1' to inbound traffic and '$fw_name_2'"
    . "to outbound traffic on the '$fw_if' dataplane interface\n";
$status = $vRouter->set_dataplane_interface_firewall(ifName => $fw_if,
                                                     inFw   => $fw_name_1,
                                                     outFw  => $fw_name_2);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "Firewall instances were successfully applied to the '$fw_if'"
    . "dataplane interface\n\n";


show_dpif_cfg($vRouter, $fw_if);


print "<<< Remove firewall settings from the '$fw_if' dataplane interface\n";
$status = $vRouter->delete_dataplane_interface_firewall($fw_if);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "Firewall settings successfully removed from "
    ."'$vRouter->{name}' dataplane interface\n\n";


show_dpif_cfg($vRouter, $fw_if);


print ">>> Remove firewall instance '$fw_name_1' from '$vRouter->{name}'\n";
$status = $vRouter->delete_firewall_instance($fw1);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "Firewall instance '$fw_name_1' was successfully deleted\n\n";


print ">>> Remove firewall instance '$fw_name_2' from '$vRouter->{name}'\n";
$status = $vRouter->delete_firewall_instance($fw2);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "Firewall instance '$fw_name_2' was successfully deleted\n\n";


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

    print "<<< Show firewalls configuration on the '$vRouter->{name}'\n";
    ($status, $fwcfg) = $vRouter->get_firewalls_cfg();
    if ($status->no_data) {
	print "No firewall configuration found.\n";
	return;
    }
    $status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
    print "'$vRouter->{name}' firewalls config:\n";
    print JSON->new->canonical->pretty->encode(JSON::decode_json($fwcfg))
        . "\n";
}

sub show_dpif_cfg {
    my ($vRouter, $ifname) = @_;

    print "<<< Show '$ifname' dataplane interface configuration "
        . "on the '$vRouter->{name}'\n";
    ($status, $ifcfg) = $vRouter->get_dataplane_interface_cfg($fw_if);
    $status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
    print "Interfaces '$ifname' config:\n";
    print JSON->new->canonical->pretty->encode(JSON::decode_json($ifcfg))
        . "\n";
}
