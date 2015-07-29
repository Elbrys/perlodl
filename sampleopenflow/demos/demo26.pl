#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Const qw(/ETH_TYPE/);
use Brocade::BSC::Node::OF::Switch;
use Brocade::BSC::Node::OF::FlowEntry;
use Brocade::BSC::Node::OF::Match;
use Brocade::BSC::Node::OF::Action::Drop;
use Brocade::BSC::Node::OF::Action::Output;
use Brocade::BSC::Node::OF::Action::SetField;
use Brocade::BSC::Node::OF::Action::PushVlanHeader;
use Brocade::BSC::Node::OF::Action::PopVlanHeader;

my $configfile = "";
my $status = undef;

my $table_id     = 0;
my $flow_id_base = 12;
my $flow_id      = $flow_id_base;
my @flow_entries = ();

my $flow_entry   = undef;
my $instruction  = undef;
my $action       = undef;
my $match        = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $ofswitch = new Brocade::BSC::Node::OF::Switch(cfgfile => $configfile,
                                                    ctrl => $bvc);
print "<<< 'Controller': $bvc->{ipAddr}, 'OpenFlow' switch: $ofswitch->{name}\n\n";

#-----------------------------------------------
# create all sample flows
#-----------------------------------------------

$flow_entry = new Brocade::BSC::Node::OF::FlowEntry;
$flow_entry->id($flow_id++);
$flow_entry->cookie(6001);
$flow_entry->table_id($table_id);
$flow_entry->idle_timeout(12000);
$flow_entry->hard_timeout(12000);
$flow_entry->priority(1000);

$instruction = $flow_entry->add_instruction(0);
$action = new Brocade::BSC::Node::OF::Action::Drop(order => 0);
$instruction->apply_actions($action);

$match = new Brocade::BSC::Node::OF::Match;
$match->eth_type($ETH_TYPE_ARP);
$match->eth_src('00:11:22:33:44:55');
$match->eth_dst('aa:bb:cc:dd:ee:ff');
$flow_entry->add_match($match);

push @flow_entries, $flow_entry;

#-----------------------------------------------

$flow_entry = new Brocade::BSC::Node::OF::FlowEntry;
$flow_entry->id($flow_id++);
$flow_entry->cookie(7001);
$flow_entry->table_id($table_id);
$flow_entry->idle_timeout(2400);
$flow_entry->hard_timeout(2400);
$flow_entry->priority(2000);

$instruction = $flow_entry->add_instruction(0);
$action = new Brocade::BSC::Node::OF::Action::Output(order   => 0,
                                                     port    => 'CONTROLLER',
                                                     max_len => 60);
$instruction->apply_actions($action);

$match = new Brocade::BSC::Node::OF::Match;
$match->eth_type($ETH_TYPE_IPv4);
$match->ipv4_src('1.2.3.4/32');
$match->ipv4_dst('192.168.1.11/32');
$flow_entry->add_match($match);

push @flow_entries, $flow_entry;

#-----------------------------------------------

$flow_entry = new Brocade::BSC::Node::OF::FlowEntry;
$flow_entry->id($flow_id++);
$flow_entry->cookie(800);
$flow_entry->table_id($table_id);
$flow_entry->idle_timeout(1800);
$flow_entry->hard_timeout(1800);
$flow_entry->priority(3000);

$instruction = $flow_entry->add_instruction(0);
$action = new Brocade::BSC::Node::OF::Action::Output(order => 0, port => 5);
$instruction->apply_actions($action);
$action = new Brocade::BSC::Node::OF::Action::Output(order => 1, port => 6);
$instruction->apply_actions($action);
$action = new Brocade::BSC::Node::OF::Action::Output(order => 2, port => 7);
$instruction->apply_actions($action);

$match = new Brocade::BSC::Node::OF::Match;
$match->in_port(1);
$flow_entry->add_match($match);

push @flow_entries, $flow_entry;

#-----------------------------------------------

$flow_entry = new Brocade::BSC::Node::OF::FlowEntry;
$flow_entry->id($flow_id++);
$flow_entry->cookie(1234);
$flow_entry->table_id($table_id);
$flow_entry->idle_timeout(0);
$flow_entry->hard_timeout(0);
$flow_entry->priority(4000);

$instruction = $flow_entry->add_instruction(0);
$action = new Brocade::BSC::Node::OF::Action::PushVlanHeader(order => 0);
$action->eth_type($ETH_TYPE_QINQ);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::SetField(order => 1);
$action->vlan_id(100);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::PushVlanHeader(order => 2);
$action->eth_type($ETH_TYPE_DOT1Q);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::SetField(order => 3);
$action->vlan_id(998);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::Output(order => 4, port => 111);
$instruction->apply_actions($action);

$match = new Brocade::BSC::Node::OF::Match;
$match->eth_type($ETH_TYPE_ARP);
$match->vlan_id(998);
$match->in_port(110);
$flow_entry->add_match($match);

push @flow_entries, $flow_entry;

#-----------------------------------------------

$flow_entry = new Brocade::BSC::Node::OF::FlowEntry;
$flow_entry->id($flow_id++);
$flow_entry->cookie(1235);
$flow_entry->table_id($table_id);
$flow_entry->idle_timeout(0);
$flow_entry->hard_timeout(0);
$flow_entry->priority(4000);

$instruction = $flow_entry->add_instruction(0);
$action = new Brocade::BSC::Node::OF::Action::PushVlanHeader(order => 0);
$action->eth_type($ETH_TYPE_QINQ);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::SetField(order => 1);
$action->vlan_id(100);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::PushVlanHeader(order => 2);
$action->eth_type($ETH_TYPE_DOT1Q);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::SetField(order => 3);
$action->vlan_id(998);
$instruction->apply_actions($action);

$action = new Brocade::BSC::Node::OF::Action::Output(order => 4, port => 111);
$instruction->apply_actions($action);

$match = new Brocade::BSC::Node::OF::Match;
$match->eth_type($ETH_TYPE_IPv4);
$match->vlan_id(998);
$match->in_port(110);
$flow_entry->add_match($match);

push @flow_entries, $flow_entry;

#-----------------------------------------------

$flow_entry = new Brocade::BSC::Node::OF::FlowEntry;
$flow_entry->id($flow_id++);
$flow_entry->cookie(1236);
$flow_entry->table_id($table_id);
$flow_entry->idle_timeout(0);
$flow_entry->hard_timeout(0);
$flow_entry->priority(4000);

$instruction = $flow_entry->add_instruction(0);
$action = new Brocade::BSC::Node::OF::Action::PopVlanHeader(order => 0);
$instruction->apply_actions($action);
$action = new Brocade::BSC::Node::OF::Action::Output(order => 1, port => 110);
$instruction->apply_actions($action);

$match = new Brocade::BSC::Node::OF::Match;
$match->eth_type($ETH_TYPE_ARP);
$match->vlan_id(100);
$match->in_port(111);
$flow_entry->add_match($match);

push @flow_entries, $flow_entry;

#-----------------------------------------------

$flow_entry = new Brocade::BSC::Node::OF::FlowEntry;
$flow_entry->id($flow_id++);
$flow_entry->cookie(1237);
$flow_entry->table_id($table_id);
$flow_entry->idle_timeout(0);
$flow_entry->hard_timeout(0);
$flow_entry->priority(4000);

$instruction = $flow_entry->add_instruction(0);
$action = new Brocade::BSC::Node::OF::Action::PopVlanHeader(order => 0);
$instruction->apply_actions($action);
$action = new Brocade::BSC::Node::OF::Action::Output(order => 1, port => 110);
$instruction->apply_actions($action);

$match = new Brocade::BSC::Node::OF::Match;
$match->eth_type($ETH_TYPE_IPv4);
$match->vlan_id(100);
$match->in_port(111);
$flow_entry->add_match($match);

push @flow_entries, $flow_entry;

#-----------------------------------------------

print "<<< Remove configured flows from the Controller\n\n";
$ofswitch->delete_flows($table_id);

print "<<< Set OpenFlow flows on the Controller\n\n";

print "<<< Flows to be configured:\n\n";
@flow_entries = sort { $a->{priority} <=> $b->{priority} } @flow_entries;
foreach $flow_entry (@flow_entries) {
    print $flow_entry->as_oxm . "\n";
}

foreach $flow_entry (@flow_entries) {
    $status = $ofswitch->add_modify_flow($flow_entry);

    if (not $status->ok) {
        $ofswitch->delete_flows($table_id);
        print "!!! Demo terminated, failed to add flow:\n";
        print $flow_entry->as_oxm . "\n";
        die   "Failure reason: ${\$status->msg}\n";
    }
}
print "\n";

print "<<< Flows successfully added to the controller\n\n";

print "<<< Get configured flows from the Controller\n\n";
print "<<< Configured flows:\n";

($status, my $flow_entries_ref) = $ofswitch->get_configured_FlowEntries($table_id);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

@flow_entries = sort { $a->{priority} <=> $b->{priority} } @$flow_entries_ref;
foreach $flow_entry (@flow_entries) {
    print $flow_entry->as_oxm . "\n";
}
print "\n";

print "<<< Get configured flows by IDs from the Controller:\n";
foreach my $ii ($flow_id_base .. $flow_id-1) {
    ($status, $flow_entry) = $ofswitch->get_configured_FlowEntry($table_id,
                                                                 $ii);
    if (not $status->ok) {
        $ofswitch->delete_flows($table_id);
        print "!!! Demo terminated, failed to add flow:\n";
        print $flow_entry->as_oxm . "\n";
        die   "Failure reason: ${\$status->msg}\n";
    }
    print " [Flow ID '$ii']\n";
    print $flow_entry->as_oxm . "\n";
}
print "\n";

print "<<< Remove configured flows from the Controller\n\n";
$ofswitch->delete_flows($table_id);

print "<<< Get configured flows from the Controller\n\n";
($status, $flow_entries_ref) = $ofswitch->get_configured_FlowEntries($table_id);
$status->no_data or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< No configured flows\n\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
