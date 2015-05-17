#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Openflow::OFSwitch;
use BVC::Openflow::FlowEntry;
use BVC::Openflow::Match;
use BVC::Openflow::Action::Drop;

my $configfile = "";
my $status = $BVC_UNKNOWN;
my $flowinfo = undef;

my $sample = "openflow:1";
my $ethtype = 0x0800;
my $ipv4_dst = "10.11.12.13/24";
my $table_id = 0;
my $flow_id  = 11;
my $flow_priority = 1000;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $ofswitch = new BVC::Openflow::OFSwitch(ctrl => $bvc, name => $sample);
print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $sample\n\n";

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match: Ethernet Type (0x%04x)\n", $ethtype;
print  "        IPv4 Destination Address ($ipv4_dst)\n";
print  "        Action: Drop\n\n";

my $flowentry = new BVC::Openflow::FlowEntry;
$flowentry->table_id($table_id);
$flowentry->id($flow_id);
$flowentry->priority($flow_priority);

# # --- Instruction: 'Apply-action'
# #     Action:      'Drop'
my $instruction = $flowentry->add_instruction(0);
my $action = new BVC::Openflow::Action::Drop(order => 0);
$instruction->apply_actions($action);

# # --- Match Fields: Ethernet Type
# #                   IPv4 Destination Address
my $match = new BVC::Openflow::Match();
$match->eth_type($ethtype);
$match->ipv4_dst($ipv4_dst);
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
