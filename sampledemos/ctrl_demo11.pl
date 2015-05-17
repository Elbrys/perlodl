#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::NetconfNode;

my $status = $BVC_UNKNOWN;
my $result = undef;
my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

print ("\n<<< Creating Controller instance\n");
my $bvc = new BVC::Controller(cfgfile => $configfile);
print "'Controller':\n";
print $bvc->as_json() . "\n";

show_all_nodes_in_config($bvc);

my $ncNode = new BVC::NetconfNode(cfgfile => $configfile, ctrl=>$bvc);
print "<<< Creating new '" . $ncNode->{name} . "' NETCONF node\n";
print "'" . $ncNode->{name} . "':\n";
print $ncNode->as_json() . "\n";

print "<<< Check '" . $ncNode->{name} . "' NETCONF node availability on the network\n";
$status = system ("ping -c 1 " . $ncNode->{ipAddr});
$status >>= 8;  # wait()
if (0 == $status) {
    print $ncNode->{ipAddr} . " is up!\n\n";
}
else {
    die $ncNode->{ipAddr} . " is down!\n!!!Demo terminated\n\n";
}

print "<<< Add '", $ncNode->{name}, "' NETCONF node to the Controller\n";
($status, $result) = $bvc->add_netconf_node($ncNode);
if ($status == $BVC_OK) {
    print "'", $ncNode->{name}, "' NETCONF node was successfully added to the Controller\n\n";
}
else {
    die "\n!!! Demo terminated, reason: " . $bvc->status_string($status, $result) . "\n\n";
}
sleep(5);    

show_all_nodes_in_config($bvc);

print "<<< Find the '", $ncNode->{name}, "' NETCONF node on the Controller\n";
$status = $bvc->check_node_config_status($ncNode->{name});
if ($status == $BVC_NODE_CONFIGURED) {
    print "'", $ncNode->{name}, "' node is configured\n\n";
}
else {
    die "\n!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n\n";
}

print "<<< Show connection status for all NETCONF nodes configured on the Controller\n";
($status, $result) = $bvc->get_all_nodes_conn_status();
if ($status == $BVC_OK) {
    print "Nodes connection status:\n";
    foreach (@$result) {
        print "    '", $_->{'id'}, "' is";
        print $_->{'connected'} ? "" : " not";
        print " connected\n";
    }
    print "\n";
}
else {
    die "\n!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n\n";
}

show_node_conn_status($bvc, $ncNode);

print ">>> Remove '", $ncNode->{name} ,"' NETCONF node from the Controller\n";
($status, $result) = $bvc->delete_netconf_node($ncNode);
if ($status == $BVC_OK) {
    print "'", $ncNode->{name}, "' NETCONF node was successfully removed from the Controller\n\n";
}
else {
    die "\n!!! Demo terminated, reason: " . $bvc->status_string($status, $result) . "\n\n";
}
sleep(5);

show_all_nodes_in_config($bvc);

show_node_conn_status($bvc, $ncNode);

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n");


sub show_all_nodes_in_config {
    my $bvc = shift;
    
    print "<<< Show NETCONF nodes configured on the Controller\n";
    my ($status, $result) = $bvc->get_all_nodes_in_config();
    if ($status == $BVC_OK) {
        print "Nodes configured:\n";
        foreach (@$result) {
            print "    '$_'\n";
        }
        print "\n";
    }
    else {
        die "\n!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n\n";
    }
}


sub show_node_conn_status {
    my ($bvc, $ncNode) = @_;

    print "<<< Show connection status for the '", $ncNode->{name}, "' NETCONF node\n";
    my $status = $bvc->check_node_conn_status($ncNode->{name});
    if ($status == $BVC_NODE_CONNECTED) {
        print "'", $ncNode->{name}, "' node is connected\n\n";
    }
    elsif ($status == $BVC_NODE_DISCONNECTED) {
        print "'", $ncNode->{name}, "' node is not connected\n\n";
    }
    elsif ($status == $BVC_NODE_NOT_FOUND) {
        print "'", $ncNode->{name}, "' node is not found\n\n";
    }
    else {
        die "\n!!! Demo terminated, reason: " . $bvc->status_string($status) . "\n\n";
    }
}
