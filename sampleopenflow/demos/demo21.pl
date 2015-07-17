#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Const qw(/ETH_TYPE/ /IP_/);
use Brocade::BSC::Openflow::OFSwitch;
use Brocade::BSC::Openflow::FlowEntry;
use Brocade::BSC::Openflow::Match;
use Brocade::BSC::Openflow::Action::Output;

my $configfile = "";
my $status = undef;
my $flowinfo = undef;

my $ethtype = $ETH_TYPE_IPv6;
my $ipv6_src = '1234:5678:9ABC:DEF0:FDCD:A987:6543:210F/76';
my $ipv6_dst = '2000:2abc:edff:fe00::3456/94';
my $ipv6_flabel = 7;
my $ipv6_exthdr = 0;  # no next header
my $ip_ecn = $IP_ECN_CE;
my $ip_dscp = $IP_DSCP_CS6;
my $ip_proto = $IP_PROTO_TCP;
my $tcp_src_port = 1831;
my $tcp_dst_port = 1006;
my $metadata = '123456789';
my $output_port = 'CONTROLLER';

my $table_id = 0;
my $flow_id  = 27;
my $flow_priority = 1020;
my $cookie = 2100;
my $hard_timeout = 1234;
my $idle_timeout = 3456;
my $strict = 0;
my $install_hw = 0;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $ofswitch = new Brocade::BSC::Openflow::OFSwitch(cfgfile => $configfile,
                                                    ctrl => $bvc);
print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $ofswitch->{name}\n\n";

print  "<<< Set OpenFlow flow on the Controller\n";
printf "        Match:  Ethernet Type        (0x%04x)\n", $ethtype;
print  "                IP DSCP              ($ip_dscp)\n";
print  "                IP ECN               ($ip_ecn)\n";
print  "                IPv6 Source Address  ($ipv6_src)\n";
print  "                IPv6 Dest Address    ($ipv6_dst)\n";
print  "                IPv6 Flow Label      ($ipv6_flabel)\n";
print  "                IPv6 Extension Hdr   ($ipv6_exthdr)\n";
print  "                TCP Source Port      ($tcp_src_port)\n";
print  "                TCP Destination Port ($tcp_dst_port)\n";
print  "                Metadata             ($metadata)\n";
print  "        Action: Output (to $output_port)\n\n";

my $flowentry = new Brocade::BSC::Openflow::FlowEntry;
$flowentry->flow_name(__FILE__);
$flowentry->table_id($table_id);
$flowentry->id($flow_id);
$flowentry->priority($flow_priority);
$flowentry->cookie($cookie);
$flowentry->hard_timeout($hard_timeout);
$flowentry->idle_timeout($idle_timeout);
$flowentry->strict($strict);
$flowentry->install_hw($install_hw);

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
$match->ipv6_flabel($ipv6_flabel);
$match->ipv6_ext_header($ipv6_exthdr);
$match->ip_proto($ip_proto);
$match->ip_dscp($ip_dscp);
$match->ip_ecn($ip_ecn);
$match->tcp_src_port($tcp_src_port);
$match->tcp_dst_port($tcp_dst_port);
$match->metadata($metadata);
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
