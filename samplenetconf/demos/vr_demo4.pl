#!/usr/bin/perl

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

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Node::NC::Vrouter::VR5600;
use Brocade::BSC::Node::NC::Vrouter::Firewall;

my $configfile = "";
my $status = undef;
my $fwcfg = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

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


my $fw_group = "FW-ACCEPT-SRC-172_22_17_108";
print "<<< Create new firewall instance '$fw_group' on ' $vRouter->{name}'\n\n";
my $firewall = new Brocade::BSC::Node::NC::Vrouter::Firewall;
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

