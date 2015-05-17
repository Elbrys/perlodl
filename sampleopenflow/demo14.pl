#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Openflow::OFSwitch;
use BVC::Openflow::FlowEntry;
use BVC::Openflow::Match;
use BVC::Openflow::Action::Output;
use BVC::Openflow::Action::SetField;
use BVC::Openflow::Action::PushVlanHeader;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $flowinfo = undef;

my $sample = "openflow:1";
my $ethtype = 0x0800;                   # IPv4
my $eth_src = "00:00:00:aa:bb:cc";
my $eth_dst = "ff:ff:aa:bc:ed:fe";
my $input_port = 5;

my $push_eth_type = 0x8100;     # VLAN tagged frame
#                   0x88a8        Q-in-Q VLAN tagged frame
my $push_vlan_id = 100;
my $output_port = 5;

my $table_id = 0;
my $flow_id  = 21;
my $flow_priority = 1012;
my $cookie = 401;
my $cookie_mask = 255;
my $hard_timeout = 1200;
my $idle_timeout = 3400;

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
print  "                Input Port                   ($input_port)\n";
printf "        Action: 'Push VLAN'         (Eth Type 0x%04x)\n", $push_eth_type;
print  "                'Set Field'         (VLAN ID  $push_vlan_id)\n";
print  "                'Output' (to Physical Port Number $output_port)\n\n";

my $flowentry = new BVC::Openflow::FlowEntry;
$flowentry->flow_name("push_vlan_flow");
$flowentry->table_id($table_id);
$flowentry->id($flow_id);
$flowentry->priority($flow_priority);
$flowentry->cookie($cookie);
$flowentry->cookie_mask($cookie_mask);
$flowentry->hard_timeout($hard_timeout);
$flowentry->idle_timeout($idle_timeout);

# # --- Instruction: 'Apply-action'
# #     Action:      'Output' NORMAL
my $instruction = $flowentry->add_instruction(0);

my $action = new BVC::Openflow::Action::PushVlanHeader(order => 0);
$action->eth_type($push_eth_type);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::SetField(order => 1);
$action->vlan_id($push_vlan_id);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::Output(order => 2,
                                            port => $output_port);
$instruction->apply_actions($action);

# # --- Match Fields

my $match = new BVC::Openflow::Match();
$match->eth_type($ethtype);
$match->eth_src($eth_src);
$match->eth_dst($eth_dst);
$match->in_port($input_port);
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
