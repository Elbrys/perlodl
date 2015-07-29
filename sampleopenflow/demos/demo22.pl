#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Const qw(/ETH_TYPE/);
use Brocade::BSC::Node::OF::Switch;
use Brocade::BSC::Node::OF::FlowEntry;
use Brocade::BSC::Node::OF::Match;
use Brocade::BSC::Node::OF::Action::Output;
use Brocade::BSC::Node::OF::Action::SetField;
use Brocade::BSC::Node::OF::Action::PushMplsHeader;

my $configfile = "";
my $status = undef;
my $flowinfo = undef;

my $ethtype = $ETH_TYPE_IPv4;
my $input_port = 13;
my $ipv4_dst = '10.12.5.4/32';

my $push_ether_type = $ETH_TYPE_MPLS_UCAST;
my $mpls_label = 27;
my $output_port = 14;

my $table_id = 0;
my $flow_id  = 28;
my $flow_priority = 1021;
my $cookie = 654;
my $cookie_mask = 255;
my $hard_timeout = 0;
my $idle_timeout = 0;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $ofswitch = new Brocade::BSC::Node::OF::Switch(cfgfile => $configfile,
                                                    ctrl => $bvc);
print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $ofswitch->{name}\n\n";

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type        (0x%04x)\n", $ethtype;
print  "                Input Port           ($input_port)\n";
print  "                IPv4 Destination     ($ipv4_dst)\n";
print  "        Action: Push MPLS Header     (Ethernet Type $push_ether_type)\n";
print  "                Set Field            (MPLS label $mpls_label)\n";
print  "                Output (to $output_port)\n\n";

my $flowentry = new Brocade::BSC::Node::OF::FlowEntry;
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

my $action = new Brocade::BSC::Node::OF::Action::PushMplsHeader(order => 0);
$action->eth_type($push_ether_type);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::SetField(order => 1);
$action->mpls_label($mpls_label);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::Output(order => 2, port => $output_port);
$instruction->apply_actions($action);

# # --- Match Fields

my $match = new Brocade::BSC::Node::OF::Match();
$match->eth_type($ethtype);
$match->in_port($input_port);
$match->ipv4_dst($ipv4_dst);
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
print "        and from table '$table_id' on the '$ofswitch->{name}' node\n\n";
$status = $ofswitch->delete_flow($flowentry->table_id,
                                 $flowentry->id);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< Flow successfully removed from the Controller\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
