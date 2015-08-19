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
use Brocade::BSC::Node::NC::Vrouter::VR5600;
use Brocade::BSC::Node::NC::Vrouter::OvpnIf;
use Brocade::BSC::Node::NC::Vrouter::StaticRoute;

my $configfile = "";
my $status = undef;
my $ovpn_ifcfg = undef;
my $ifname = 'vtun0';
my $route_cfg = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

print "<<< OpenVPN configuration example: Site-to-Site Mode with TLS\n\n";

my $bsc = new Brocade::BSC(cfgfile => $configfile);
my $vRouter = new Brocade::BSC::Node::NC::Vrouter::VR5600(cfgfile => $configfile,
                                                          ctrl=>$bsc);

print "<<< 'Controller': $bsc->{ipAddr}, '"
    . "$vRouter->{name}': $vRouter->{ipAddr}\n\n";


$status = $bsc->add_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' added to the Controller\n\n";
sleep(2);


$status = $bsc->check_node_conn_status($vRouter->{name});
$status->connected or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' is connected to the Controller\n\n";


print "<<< Show OpenVPN interfaces configuration on the '$vRouter->{name}'\n";
($status, $ovpn_ifcfg) = $vRouter->get_openvpn_interfaces_cfg();
if ($status->ok) {
    print "'$vRouter->{name}' OpenVPN interfaces configuration:\n";
    print JSON->new->pretty->encode($ovpn_ifcfg) . "\n\n";
}
elsif ($status->no_data) {
    print "No OpenVPN interfaces configuration found.\n\n";
}
else {
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
}


print ">>> Configure new '$ifname' OpenVPN tunnel interface on the '$vRouter->{name}'\n";
my $vpnif = new Brocade::BSC::Node::NC::Vrouter::OvpnIf($ifname);


#=======================================================================
#=======================================================================
#=======================================================================


$vpnif->mode('site-to-site');
$vpnif->local_address('192.168.200.1');
$vpnif->remote_address('192.168.200.2');
$vpnif->remote_host('87.65.43.21');
$vpnif->tls_role('passive');

$vpnif->tls_ca_cert_file('/config/auth/ca.crt');
$vpnif->tls_cert_file('/config/auth/V1.crt');
$vpnif->tls_crl_file('/config/auth/crl.pem');
$vpnif->tls_dh_file('/config/auth/dh1024.pem');
$vpnif->tls_key_file('/config/auth/V1.key');


$status = $vRouter->set_openvpn_interface_cfg($vpnif);
$status->ok or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' interface configuration was successfully created\n\n";


print "<<< Show '$ifname' interface configuration on '$vRouter->{name}'\n";
($status, $ovpn_ifcfg) = $vRouter->get_openvpn_interface_cfg($ifname);
$status->ok or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "'$ifname' interface configuration:\n";
print JSON->new->canonical->pretty->encode(JSON::decode_json($ovpn_ifcfg));
print "<<< '$ifname' interface configuration was successfully read.\n\n";


my $remote_subnet = '192.168.101.0/24';
print "<<< Create static route to access the remote subnet '$remote_subnet' "
    . "through the '$ifname' interface.\n";
my $route = new Brocade::BSC::Node::NC::Vrouter::StaticRoute;
$route->interface_route($remote_subnet);
$route->interface_route_next_hop_interface(subnet => $remote_subnet,
                                           ifname => $ifname);


$status = $vRouter->set_protocols_static_route_cfg($route);
$status->ok or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "<<< Static route was successfully created.\n\n";


print "<<< Show subnet '$remote_subnet' static route configuration on '$vRouter->{name}'\n";
($status, $route_cfg) = $vRouter->get_protocols_static_interface_route_cfg($remote_subnet);
$status->ok or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "Static route configuration:\n";
print JSON->new->canonical->pretty->encode(JSON::decode_json($route_cfg));
print "<<< Static route configuration was successfully read.\n\n";


print "<<< Delete '$ifname' interface configuration from the '$vRouter->{name}'\n";
$status = $vRouter->delete_openvpn_interface_cfg($ifname);
$status->ok or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$ifname' interface configuration successfully removed "
    . "from the '$vRouter->{name}'\n\n";


print "<<< Show '$ifname' interface configuration on '$vRouter->{name}'\n";
($status, $ovpn_ifcfg) = $vRouter->get_openvpn_interface_cfg($ifname);
$status->no_data or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: "
        . $status->ok ? "Interface configuration still exists\n" : "${\$status->msg}\n";
print "No '$ifname' interface configuration found.\n\n";


print "<<< Delete '$remote_subnet' subnet static route configuration from the '$vRouter->{name}'\n";
$status = $vRouter->delete_protocols_static_interface_route_cfg($remote_subnet);
$status->ok or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "<<< Static route configuration successfully removed from '$vRouter->{name}'\n\n";


print "<<< Show subnet '$remote_subnet' static route configuration on '$vRouter->{name}'\n";
($status, $route_cfg) = $vRouter->get_protocols_static_interface_route_cfg($remote_subnet);
$status->no_data or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: "
        . $status->ok ? "Static route configuration still found\n" : "${\$status->msg}\n";
print "No static route configuration found.\n\n";


print ">>> Remove '$vRouter->{name}' NETCONF node from the Controller\n";
$status = $bsc->delete_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "'$vRouter->{name}' NETCONF node was successfully removed from the Controller\n\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
