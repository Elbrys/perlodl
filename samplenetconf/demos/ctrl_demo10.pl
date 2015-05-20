#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::NetconfNode;

my $status = undef;
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

show_netconf_nodes_in_config($bvc);

my $ncNode = new BVC::NetconfNode(cfgfile => $configfile, ctrl=>$bvc);
print "<<< Creating new '$ncNode->{name}' NETCONF node\n";
print "'$ncNode->{name}':\n";
print $ncNode->as_json() . "\n";

print "<<< Add '$ncNode->{name}' NETCONF node to the Controller\n";
$status = $bvc->add_netconf_node($ncNode);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "'$ncNode->{name}' NETCONF node was successfully added to the Controller\n\n";

sleep(2);    

show_netconf_nodes_in_config($bvc);

print "<<< Find the '$ncNode->{name}' NETCONF node on the Controller\n";
$status = $bvc->check_node_config_status($ncNode->{name});

$status->configured or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "'$ncNode->{name}' node is configured\n\n";

print "<<< Show connection status for all NETCONF nodes configured on the Controller\n";
($status, $result) = $bvc->get_netconf_nodes_conn_status();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Nodes connection status:\n";
foreach (@$result) {
    print "    '", $_->{'id'}, "' is";
    print $_->{'connected'} ? "" : " not";
    print " connected\n";
}
print "\n";

show_node_conn_status($bvc, $ncNode);

print ">>> Remove '$ncNode->{name}' NETCONF node from the Controller\n";
$status = $bvc->delete_netconf_node($ncNode);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "'$ncNode->{name}' NETCONF node was successfully removed from the Controller\n\n";
sleep(2);

show_netconf_nodes_in_config($bvc);

show_node_conn_status($bvc, $ncNode);

print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n");


sub show_netconf_nodes_in_config {
    my $bvc = shift;
    
    print "<<< Show NETCONF nodes configured on the Controller\n";
    my ($status, $result) = $bvc->get_netconf_nodes_in_config();
    $status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

    print "Nodes configured:\n";
    foreach (@$result) {
        print "    '$_'\n";
    }
    print "\n";
}


sub show_node_conn_status {
    my ($bvc, $ncNode) = @_;

    print "<<< Show connection status for the '", $ncNode->{name}, "' NETCONF node\n";
    my $status = $bvc->check_node_conn_status($ncNode->{name});

    if ($status->connected || $status->disconnected || $status->not_found) {
        print "'$ncNode->{name}': ${\$status->msg}\n\n";
    }
    else {
        die "!!! Demo terminated, reason: ${\$status->msg}\n";
    }
}
