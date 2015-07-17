#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Const qw(/ETH_TYPE/);
use Brocade::BSC::Openflow::OFSwitch;
use Brocade::BSC::Openflow::FlowEntry;
use Brocade::BSC::Openflow::Match;
use Brocade::BSC::Openflow::Action::Output;

my $configfile = "";
my $status = undef;
my $flowinfo = undef;

my $ethtype = $ETH_TYPE_IPv6;
my $ipv6_src = 'fe80::2acf:e9ff:fe21:6431/128';
my $ipv6_dst = 'aabb:1234:2acf:e9ff::fe21:6431/64';
my $output_port = 'CONTROLLER';

my $table_id = 0;
my $flow_id  = 23;
my $flow_priority = 1014;
my $cookie = 408;
my $cookie_mask = 255;
my $hard_timeout = 3400;
my $idle_timeout = 3400;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $ofswitch = new Brocade::BSC::Openflow::OFSwitch(cfgfile => $configfile,
                                                    ctrl => $bvc);
print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $ofswitch->{name}\n\n";

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type       (0x%04x)\n", $ethtype;
print  "                IPv6 Source Address ($ipv6_src)\n";
print  "                IPv6 Dest Address   ($ipv6_dst)\n";
print  "        Action: Output (to $output_port)\n\n";

my $flowentry = new Brocade::BSC::Openflow::FlowEntry;
$flowentry->flow_name("match=ipv6_src,ipv6_dst");
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
my $action = new Brocade::BSC::Openflow::Action::Output(order => 0,
                                               port => $output_port);
$instruction->apply_actions($action);

# # --- Match Fields

my $match = new Brocade::BSC::Openflow::Match();
$match->eth_type($ethtype);
$match->ipv6_src($ipv6_src);
$match->ipv6_dst($ipv6_dst);
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
