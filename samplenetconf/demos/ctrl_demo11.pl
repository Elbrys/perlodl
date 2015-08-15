#!/usr/bin/perl

# Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Node::NC;

my $status = undef;
my $result = undef;
my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");

print ("\n<<< Creating Controller instance\n");
my $bvc = new Brocade::BSC(cfgfile => $configfile);
print "'Controller':\n";
print $bvc->as_json() . "\n";

show_netconf_nodes_in_config($bvc);

my $ncNode = new Brocade::BSC::Node::NC(cfgfile => $configfile, ctrl=>$bvc);
print "<<< Creating new '$ncNode->{name}' NETCONF node\n";
print "'$ncNode->{name}':\n";
print $ncNode->as_json() . "\n";

print "<<< Check '$ncNode->{name}' NETCONF node availability on the network\n";
system ("ping -c 1 " . $ncNode->{ipAddr}) and
    die "!!! Demo terminated, reason: $ncNode->{ipAddr} is down\n";
print "$ncNode->{ipAddr} is up!\n\n";

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
