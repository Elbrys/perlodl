#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Openflow::OFSwitch;
use BVC::Openflow::FlowEntry;
use BVC::Openflow::Match;
use BVC::Openflow::Action::Output;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $flowinfo = undef;

my $sample = "openflow:1";
my $ethtype = 0x0806;                   # ARP
my $eth_src = "00:ab:fe:01:03:31";
my $eth_dst = "ff:ff:ff:ff:ff:ff";
my $arp_opcode = 1;
my $arp_src_ipv4 = "192.168.4.1";
my $arp_tgt_ipv4 = "10.21.22.23";
my $arp_src_hw_addr = "12:34:56:78:98:ab";
my $arp_tgt_hw_addr = "fe:dc:ba:98:76:54";

my $table_id = 0;
my $flow_id  = 19;
my $flow_priority = 1010;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $ofswitch = new BVC::Openflow::OFSwitch(ctrl => $bvc, name => $sample);
print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $sample\n\n";

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type                (0x%04x)\n", $ethtype;
print  "                Ethernet Source Address      ($eth_src)\n";
print  "                Ethernet Destination Address ($eth_dst)\n";
print  "                ARP Operation                ($arp_opcode)\n";
print  "                ARP Source IPv4 Address      ($arp_src_ipv4)\n";
print  "                ARP Target IPv4 Address      ($arp_tgt_ipv4)\n";
print  "                ARP Source Hardware Address  ($arp_src_hw_addr)\n";
print  "                ARP Target Hardware Address  ($arp_tgt_hw_addr)\n";
print  "        Action: Output (CONTROLLER)\n\n";

my $flowentry = new BVC::Openflow::FlowEntry;
$flowentry->table_id($table_id);
$flowentry->id($flow_id);
$flowentry->priority($flow_priority);

# # --- Instruction: 'Apply-action'
# #     Action:      'Output' NORMAL
my $instruction = $flowentry->add_instruction(0);
my $action = new BVC::Openflow::Action::Output(order => 0,
                                               port => 'CONTROLLER');
$instruction->apply_actions($action);

# # --- Match Fields

my $match = new BVC::Openflow::Match();
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
($BVC_OK == $status)
    or die "!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n";
print "<<< Flow successfully added to the Controller\n\n";

($status, $flowinfo) = $ofswitch->get_configured_flow($table_id, $flow_id);
($BVC_OK == $status)
    or die "!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n";
print "<<< Flow successfully read from the Controller\n";
print "Flow info:\n";
print JSON->new->pretty->encode(JSON::decode_json($flowinfo)) . "\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
