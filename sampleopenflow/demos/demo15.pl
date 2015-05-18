#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Const (/ETH_TYPE/);
use BVC::Openflow::OFSwitch;
use BVC::Openflow::FlowEntry;
use BVC::Openflow::Match;
use BVC::Openflow::Action::Output;
use BVC::Openflow::Action::SetField;
use BVC::Openflow::Action::PushVlanHeader;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $flowinfo = undef;

my $ethtype = $ETH_TYPE_IPv4;
my $vlan_id = 100;
my $input_port = 3;

my $push_eth_type = $ETH_TYPE_DOT1AD;
my $push_vlan_id = 200;
my $output_port = 5;

my $table_id = 0;
my $flow_id  = 22;
my $flow_priority = 1013;
my $cookie = 407;
my $cookie_mask = 255;
my $hard_timeout = 3400;
my $idle_timeout = 3400;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $ofswitch = new BVC::Openflow::OFSwitch(cfgfile => $configfile,
                                           ctrl => $bvc);
print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $ofswitch->{name}\n\n";

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type                (0x%04x)\n", $ethtype;
print  "                VLAN ID                      ($vlan_id)\n";
print  "                Input Port                   ($input_port)\n";
printf "        Action: 'Push VLAN'         (Eth Type 0x%04x)\n", $push_eth_type;
print  "                'Set Field'         (VLAN ID  $push_vlan_id)\n";
print  "                'Output' (to Physical Port Number $output_port)\n\n";

my $flowentry = new BVC::Openflow::FlowEntry;
$flowentry->flow_name("push_vlan_100_flow");
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
$match->vlan_id($vlan_id);
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

print "<<< Delete flow with id of '$flow_id' from the Controller's cache\n";
print "        and from table '$table_id' on the '$ofswitch->{name}' node\n\n";
$status = $ofswitch->delete_flow($flowentry->table_id,
                                 $flowentry->id);
($BVC_OK == $status)
    or die "!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n";
print "<<< Flow successfully removed from the Controller\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
