#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Const qw(/ETH_TYPE/);
use BVC::Openflow::OFSwitch;
use BVC::Openflow::FlowEntry;
use BVC::Openflow::Match;
use BVC::Openflow::Action::Output;
use BVC::Openflow::Action::SetField;
use BVC::Openflow::Action::PushVlanHeader;
use BVC::Openflow::Action::PopVlanHeader;

my $configfile = "";
my $status = undef;
my $flowinfo = undef;

my $qinq_eth_type    = $ETH_TYPE_STAG;
my $dot1q_eth_type   = $ETH_TYPE_CTAG;
my $ip_eth_type      = $ETH_TYPE_IPv4;
my $customer_port    = 110;
my $provider_port    = 111;
my $customer_vlan_id = 998;
my $provider_vlan_id = 100;

my $table_id      = 0;
my $first_flow_id = my $flow_id  = 31;
my $flow_priority = 500;
my $cookie        = 1000;
my $cookie_mask   = 255;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $ofswitch = new BVC::Openflow::OFSwitch(cfgfile => $configfile,
                                           ctrl => $bvc);

# ---------------------------------------------------
# First flow entry
# ---------------------------------------------------

print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $ofswitch->{name}\n\n";

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type        (0x%04x)\n", $ETH_TYPE_ARP;
print  "                VLAN ID              ($customer_vlan_id)\n";
print  "                Input Port           ($customer_port)\n";
printf "        Action: Push VLAN            (Ethernet Type 0x%04x)\n",
    $qinq_eth_type;
print  "                Set Field            (VLAN ID $provider_vlan_id)\n";
printf "                Push VLAN            (Ethernet Type 0x%04x)\n",
    $dot1q_eth_type;
print  "                Set Field            (VLAN ID $customer_vlan_id)\n";
print  "                Output (Physical Port number $provider_port)\n\n";

my $flowentry = new BVC::Openflow::FlowEntry;
$flowentry->flow_name("[MLX1-A] Test flow (match:inport=110,arp;actions:"
    . "push-QINQ-tag,mod_vlan=100,push-DOT1Q-tag,mod_vlan=998,output:111)");
$flowentry->table_id($table_id);
$flowentry->id($flow_id++);
$flowentry->priority($flow_priority);
$flowentry->cookie($cookie);
$flowentry->cookie_mask($cookie_mask);
$flowentry->hard_timeout(600);
$flowentry->idle_timeout(300);

# # --- Instruction: 'Apply-action'
# #     Action:      'Output' NORMAL
my $instruction = $flowentry->add_instruction(0);

my $action_order = 0;
my $action;
$action = new BVC::Openflow::Action::PushVlanHeader(order => $action_order++);
$action->eth_type($qinq_eth_type);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::SetField(order => $action_order++);
$action->vlan_id($provider_vlan_id);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::PushVlanHeader(order => $action_order++);
$action->eth_type($dot1q_eth_type);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::SetField(order => $action_order++);
$action->vlan_id($customer_vlan_id);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::Output(order => $action_order++,
                                            port => $provider_port);
$instruction->apply_actions($action);

# # --- Match Fields

my $match = new BVC::Openflow::Match();
$match->eth_type($ETH_TYPE_ARP);
$match->vlan_id($customer_vlan_id);
$match->in_port($customer_port);
$flowentry->add_match($match);

print "<<< Flow to send:\n";
print $flowentry->get_payload() . "\n\n";

$status = $ofswitch->add_modify_flow($flowentry);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< Flow successfully added to the Controller\n\n";

# ---------------------------------------------------
# Second flow entry
# ---------------------------------------------------

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type        (0x%04x)\n", $ip_eth_type;
print  "                VLAN ID              ($customer_vlan_id)\n";
print  "                Input Port           ($customer_port)\n";
printf "        Action: Push VLAN            (Ethernet Type 0x%04x)\n",
    $qinq_eth_type;
print  "                Set Field            (VLAN ID $provider_vlan_id)\n";
printf "                Push VLAN            (Ethernet Type 0x%04x)\n",
    $dot1q_eth_type;
print  "                Set Field            (VLAN ID $customer_vlan_id)\n";
print  "                Output (Physical Port number $provider_port)\n\n";

my $flowentry2 = new BVC::Openflow::FlowEntry;
$flowentry2->flow_name("[MLX1-A] Test flow (match:inport=110,ip;actions:"
    . "push-QINQ-tag,mod_vlan=100,output:111)");
$flowentry2->table_id($table_id);
$flowentry2->id($flow_id++);
$flowentry2->priority($flow_priority);
$flowentry2->cookie($cookie);
$flowentry2->cookie_mask($cookie_mask);
$flowentry2->hard_timeout(600);
$flowentry2->idle_timeout(300);

$instruction = $flowentry2->add_instruction(0);

$action_order = 0;

$action = new BVC::Openflow::Action::PushVlanHeader(order => $action_order++);
$action->eth_type($qinq_eth_type);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::SetField(order => $action_order++);
$action->vlan_id($provider_vlan_id);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::PushVlanHeader(order => $action_order++);
$action->eth_type($dot1q_eth_type);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::SetField(order => $action_order++);
$action->vlan_id($customer_vlan_id);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::Output(order => $action_order++,
                                            port => $provider_port);
$instruction->apply_actions($action);

$match = new BVC::Openflow::Match;
$match->eth_type($ip_eth_type);
$match->vlan_id($customer_vlan_id);
$match->in_port($customer_port);
$flowentry2->add_match($match);

print "<<< Flow to send:\n";
print $flowentry2->get_payload() . "\n\n";

$status = $ofswitch->add_modify_flow($flowentry2);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< Flow successfully added to the Controller\n\n";

# ---------------------------------------------------
# Third flow entry
# ---------------------------------------------------

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type        (0x%04x)\n", $ETH_TYPE_ARP;
print  "                VLAN ID              ($provider_vlan_id)\n";
print  "                Input Port           ($provider_port)\n";
print  "        Action: Pop VLAN\n";
print  "                Output (Physical Port number $customer_port)\n\n";

my $flowentry3 = new BVC::Openflow::FlowEntry;
$flowentry3->flow_name("[MLX1-A] Test flow (match:inport=111,arp,vid=100;"
    . "actions:pop-vlan-tag,output:110)");
$flowentry3->table_id($table_id);
$flowentry3->id($flow_id++);
$flowentry3->priority($flow_priority);
$flowentry3->cookie($cookie);
$flowentry3->cookie_mask($cookie_mask);
$flowentry3->hard_timeout(600);
$flowentry3->idle_timeout(300);

$instruction = $flowentry3->add_instruction(0);

$action_order = 0;

$action = new BVC::Openflow::Action::PopVlanHeader(order => $action_order++);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::Output(order => $action_order++,
                                            port => $customer_port);
$instruction->apply_actions($action);

$match = new BVC::Openflow::Match;
$match->eth_type($ETH_TYPE_ARP);
$match->vlan_id($provider_vlan_id);
$match->in_port($provider_port);
$flowentry3->add_match($match);

print "<<< Flow to send:\n";
print $flowentry3->get_payload() . "\n\n";

$status = $ofswitch->add_modify_flow($flowentry3);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< Flow successfully added to the Controller\n\n";

# ---------------------------------------------------
# Fourth flow entry
# ---------------------------------------------------

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type        (0x%04x)\n", $ip_eth_type;
print  "                VLAN ID              ($provider_vlan_id)\n";
print  "                Input Port           ($provider_port)\n";
print  "        Action: Pop VLAN\n";
print  "                Output (Physical Port number $customer_port)\n\n";

my $flowentry4 = new BVC::Openflow::FlowEntry;
$flowentry4->flow_name("[MLX1-A] Test flow (match:inport=111,ip,vid=100;"
    . "actions:pop-vlan-tag,output:110)");
$flowentry4->table_id($table_id);
$flowentry4->id($flow_id++);
$flowentry4->priority($flow_priority);
$flowentry4->cookie($cookie);
$flowentry4->cookie_mask($cookie_mask);
$flowentry4->hard_timeout(600);
$flowentry4->idle_timeout(300);

$instruction = $flowentry4->add_instruction(0);

$action_order = 0;

$action = new BVC::Openflow::Action::PopVlanHeader(order => $action_order++);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::Output(order => $action_order++,
                                            port => $customer_port);
$instruction->apply_actions($action);

$match = new BVC::Openflow::Match;
$match->eth_type($ip_eth_type);
$match->vlan_id($provider_vlan_id);
$match->in_port($provider_port);
$flowentry4->add_match($match);

print "<<< Flow to send:\n";
print $flowentry4->get_payload() . "\n\n";

$status = $ofswitch->add_modify_flow($flowentry4);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< Flow successfully added to the Controller\n\n";

# ---------------------------------------------------
# Read flows back from Controller
# ---------------------------------------------------

print "<<< Get configured flows from the Controller\n";
foreach my $flow_num ($first_flow_id .. $flow_id-1) {
    ($status, $flowinfo) = $ofswitch->get_configured_flow($table_id, $flow_num);
    $status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

    print "<<< Flow '$flow_num' successfully read from the Controller\n";
    print "Flow info:\n";
    print JSON->new->pretty->encode(JSON::decode_json($flowinfo)) . "\n";
}

# ---------------------------------------------------
# Clean up
# ---------------------------------------------------

print "<<< Delete flows from the Controller's cache and from\n";
print "    the table '$table_id' on the '$ofswitch->{name}' node\n";

foreach my $flow_num ($first_flow_id .. $flow_id-1) {
    $status = $ofswitch->delete_flow($table_id, $flow_num);
    $status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
    print "<<< Flow with id of '$flow_num' successfully removed from the Controller\n";
}


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
