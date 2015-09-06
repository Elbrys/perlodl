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
use Brocade::BSC::Const qw(/ARP/);
use Brocade::BSC::Node::OF::Switch;
use Brocade::BSC::Node::OF::FlowEntry;
use Brocade::BSC::Node::OF::Match;
use Brocade::BSC::Node::OF::Action::Output;

my $configfile = "";
my $status     = undef;
my $flowinfo   = undef;

my $ethtype         = $ETH_TYPE_ARP;
my $eth_src         = "00:ab:fe:01:03:31";
my $eth_dst         = "ff:ff:ff:ff:ff:ff";
my $arp_opcode      = $ARP_REQUEST;
my $arp_src_ipv4    = "192.168.4.1/32";
my $arp_tgt_ipv4    = "10.21.22.23/32";
my $arp_src_hw_addr = "12:34:56:78:98:ab";
my $arp_tgt_hw_addr = "fe:dc:ba:98:76:54";

my $table_id      = 0;
my $flow_id       = 19;
my $flow_priority = 1010;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = Brocade::BSC->new(cfgfile => $configfile);
my $ofswitch = Brocade::BSC::Node::OF::Switch->new(
    cfgfile => $configfile,
    ctrl    => $bvc
);
print
"<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $ofswitch->{name}\n\n";

print "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type                (0x%04x)\n", $ethtype;
print "                Ethernet Source Address      ($eth_src)\n";
print "                Ethernet Destination Address ($eth_dst)\n";
print "                ARP Operation                ($arp_opcode)\n";
print "                ARP Source IPv4 Address      ($arp_src_ipv4)\n";
print "                ARP Target IPv4 Address      ($arp_tgt_ipv4)\n";
print "                ARP Source Hardware Address  ($arp_src_hw_addr)\n";
print "                ARP Target Hardware Address  ($arp_tgt_hw_addr)\n";
print "        Action: Output (CONTROLLER)\n\n";

my $flowentry = Brocade::BSC::Node::OF::FlowEntry->new;
$flowentry->table_id($table_id);
$flowentry->id($flow_id);
$flowentry->priority($flow_priority);

# # --- Instruction: 'Apply-action'
# #     Action:      'Output' NORMAL
my $instruction = $flowentry->add_instruction(0);
my $action      = Brocade::BSC::Node::OF::Action::Output->new(
    order => 0,
    port  => 'CONTROLLER'
);
$instruction->apply_actions($action);

# # --- Match Fields

my $match = Brocade::BSC::Node::OF::Match->new();
$match->eth_type($ethtype);
$match->eth_src($eth_src);
$match->eth_dst($eth_dst);
$match->arp_opcode($arp_opcode);
$match->arp_src_transport_address($arp_src_ipv4);
$match->arp_tgt_transport_address($arp_tgt_ipv4);
$match->arp_src_hw_address($arp_src_hw_addr);
$match->arp_tgt_hw_address($arp_tgt_hw_addr);
$flowentry->add_match($match);

print "<<< Flow to send:\n";
print $flowentry->get_payload() . "\n\n";

$status = $ofswitch->add_modify_flow($flowentry);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< Flow successfully added to the Controller\n\n";

($status, $flowinfo) = $ofswitch->get_configured_flow($table_id, $flow_id);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< Flow successfully read from the Controller\n";
print "Flow info:\n";
print JSON->new->pretty->encode(JSON::decode_json($flowinfo)) . "\n";

print "<<< Delete flow with id of '$flow_id' from the Controller's cache\n";
print
  "        and from table '$table_id' on the '$ofswitch->{name}' node\n\n";
$status = $ofswitch->delete_flow($flowentry->table_id, $flowentry->id);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< Flow successfully removed from the Controller\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
