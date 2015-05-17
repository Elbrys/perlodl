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
my $ethtype = 0x0800;                   # IPv4
my $eth_src = "00:00:00:11:23:ae";
my $eth_dst = "ff:ff:29:01:19:61";
my $ipv4_src = "19.1.2.3/10";
my $ipv4_dst = "172.168.5.6/18";
my $ip_proto = 17;                      # UDP
my $ip_dscp  = 8;
my $ip_ecn = 3;
my $udp_src_port = 25364;
my $udp_dst_port = 8080;
my $input_port = 3;

my $table_id = 0;
my $flow_id  = 17;
my $flow_priority = 1008;

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
print  "                IPv4 Source Address          ($ipv4_src)\n";
print  "                IPv4 Destination Address     ($ipv4_dst)\n";
print  "                IP Protocol Number           ($ip_proto)\n";
print  "                IP DSCP                      ($ip_dscp)\n";
print  "                IP ECN                       ($ip_ecn)\n";
print  "                UDP Source Port Number       ($udp_src_port)\n";
print  "                UDP Destination Port Number  ($udp_dst_port)\n";
print  "                Input Port                   ($input_port)\n";
print  "        Action: Output (NORMAL)\n\n";

my $flowentry = new BVC::Openflow::FlowEntry;
$flowentry->table_id($table_id);
$flowentry->id($flow_id);
$flowentry->priority($flow_priority);

# # --- Instruction: 'Apply-action'
# #     Action:      'Output' NORMAL
my $instruction = $flowentry->add_instruction(0);
my $action = new BVC::Openflow::Action::Output(order => 0,
                                               port => 'NORMAL');
$instruction->apply_actions($action);

# # --- Match Fields

my $match = new BVC::Openflow::Match();
$match->eth_type($ethtype);
$match->eth_src($eth_src);
$match->eth_dst($eth_dst);
$match->ipv4_src($ipv4_src);
$match->ipv4_dst($ipv4_dst);
$match->ip_proto($ip_proto);
$match->ip_dscp($ip_dscp);
$match->ip_ecn($ip_ecn);
$match->udp_src_port($udp_src_port);
$match->udp_dst_port($udp_dst_port);
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
