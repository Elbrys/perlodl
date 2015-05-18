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
use BVC::Openflow::Action::PopMplsHeader;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $flowinfo = undef;

my $ethtype = $ETH_TYPE_MPLS_UCAST;
my $input_port = 14;
my $mpls_label = 44;

my $pop_ether_type = $ETH_TYPE_MPLS_UCAST;
my $output_port = 13;

my $table_id = 0;
my $flow_id  = 30;
my $flow_priority = 1023;
my $cookie = 889;
my $cookie_mask = 255;
my $hard_timeout = 0;
my $idle_timeout = 0;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $ofswitch = new BVC::Openflow::OFSwitch(cfgfile => $configfile,
                                           ctrl => $bvc);
print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $ofswitch->{name}\n\n";

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type        (0x%04x)\n", $ethtype;
print  "                Input Port           ($input_port)\n";
print  "                MPLS Label           ($mpls_label)\n";
print  "        Action: Set Field            (MPLS label $mpls_label)\n";
print  "                Output (Physical Port number $output_port)\n\n";

my $flowentry = new BVC::Openflow::FlowEntry;
$flowentry->flow_name(__FILE__);
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

my $action = new BVC::Openflow::Action::PopMplsHeader(order => 0);
$action->eth_type($pop_ether_type);
$instruction->apply_actions($action);

$action = new BVC::Openflow::Action::Output(order => 1, port => $output_port);
$instruction->apply_actions($action);

# # --- Match Fields

my $match = new BVC::Openflow::Match();
$match->eth_type($ethtype);
$match->in_port($input_port);
$match->mpls_label($mpls_label);
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
