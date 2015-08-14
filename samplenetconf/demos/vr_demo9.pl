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

#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;
use Brocade::BSC::Node::NC::Vrouter::VR5600;
use Brocade::BSC::Node::NC::Vrouter::VPN;

my $configfile = "";
my $status = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
my $vRouter = new Brocade::BSC::Node::NC::Vrouter::VR5600(cfgfile => $configfile,
                                                          ctrl=>$bvc);

print "<<< 'Controller': $bvc->{ipAddr}, '"
    . "$vRouter->{name}': $vRouter->{ipAddr}\n\n";


$status = $bvc->add_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' added to the Controller\n\n";
sleep(2);


$status = $bvc->check_node_conn_status($vRouter->{name});
$status->connected or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' is connected to the Controller\n\n";


show_vpn_cfg($vRouter);


print ">>> Create new VPN configuration on '$vRouter->{name}'\n";

my $description = "Remote Access VPN Configuration Example - L2TP/IPsec with X.509 Certificates";
my $external_ipaddr = "12.34.56.78";
my $nexthop_ipaddr = "12.34.56.254";
my $nat_traversal = 1;
my $nat_allow_network = "192.168.100.0/24";
my $client_ip_pool_start = "192.168.100.11";
my $client_ip_pool_end = "192.168.100.210";
my $ipsec_auth_mode = "x509";
my $ca_cert_file  = "/config/auth/ca.crt";
my $srv_cert_file = "/config/auth/r1.crt";
my $crl_file      = "/config/auth/r1.crl";
my $srv_key_file  = "/config/auth/r1.key";
my $srv_key_pswd  = "testpassword";
my $l2tp_auth_mode = "local";
my $uname1="user1";
my $upswd1="user1_password";
my $uname2="user2";
my $upswd2="user2_password";
my $uname3="user3";
my $upswd3="user3_password";

print " NOTE: For this demo to succeed the following files must exist on the ";
print "'$vRouter->{name}'\n";
print "       (empty files can be created for the sake of the demo):\n";
print "        $ca_cert_file\n";
print "        $srv_cert_file\n";
print "        $crl_file\n";
print "        $srv_key_file\n\n";

print " VPN options to be set:\n"
    . "   - Configuration description         : '$description'\n"
    . "   - Server external address           : '$external_ipaddr'\n"
    . "   - Next hop router address           : '$nexthop_ipaddr'\n"
    . "   - NAT_traversal                     : '$nat_traversal'\n"
    . "   - NAT allowed networks              : '$nat_allow_network'\n"
    . "   - Client addresses pool (start/end) : '$client_ip_pool_start'/"
    .                                          "'$client_ip_pool_end'\n"
    . "   - IPsec authentication (mode/secret): '$ipsec_auth_mode'\n"
    . "   - CA certificate location           : '$ca_cert_file'\n"
    . "   - Server certifcate location        : '$srv_cert_file'\n"
    . "   - Certificate revocation list       : '$crl_file'\n"
    . "   - Server key file location          : '$srv_key_file'\n"
    . "   - Server key file password          : '$srv_key_pswd'\n"
    . "   - L2TP authentication  mode         : '$l2tp_auth_mode'\n"
    . "   - Allowed users (name/password)     : '$uname1'/'$upswd1'\n"
    . "                                         '$uname2'/'$upswd2'\n"
    . "                                         '$uname3'/'$upswd3'\n";

my $vpn = new Brocade::BSC::Node::NC::Vrouter::VPN();
    
$vpn->l2tp_remote_access_description($description);
$vpn->nat_traversal($nat_traversal);
$vpn->nat_allow_network($nat_allow_network);
$vpn->l2tp_remote_access_outside_address($external_ipaddr);
$vpn->l2tp_remote_access_outside_nexthop($nexthop_ipaddr);
$vpn->l2tp_remote_access_client_ip_pool(start => $client_ip_pool_start,
                                        end   => $client_ip_pool_end);

$vpn->l2tp_remote_access_ipsec_auth_mode($ipsec_auth_mode);

$vpn->l2tp_remote_access_ipsec_auth_ca_cert_file($ca_cert_file);
$vpn->l2tp_remote_access_ipsec_auth_srv_cert_file($srv_cert_file);
$vpn->l2tp_remote_access_ipsec_auth_crl_file($crl_file);
$vpn->l2tp_remote_access_ipsec_auth_srv_key_file($srv_key_file);
$vpn->l2tp_remote_access_ipsec_auth_srv_key_pswd($srv_key_pswd);


$vpn->l2tp_remote_access_user_auth_mode($l2tp_auth_mode);
$vpn->l2tp_remote_access_user(name => $uname1, pswd => $upswd1);
$vpn->l2tp_remote_access_user(name => $uname2, pswd => $upswd2);
$vpn->l2tp_remote_access_user(name => $uname3, pswd => $upswd3);


print ">>> VPN configuration to be applied to the '$vRouter->{name}'\n";
print $vpn->get_payload() . "\n\n";

$status = $vRouter->set_vpn_cfg($vpn);
$status->ok or
    $bvc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "<<< VPN configuration was successfully created.\n\n";


show_vpn_cfg($vRouter);


print "<<< Delete VPN configuration on the '$vRouter->{name}'\n";
$status = $vRouter->delete_vpn_cfg();
$status->ok or
    $bvc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "VPN configuration successfully removed from '$vRouter->{name}'\n\n";


show_vpn_cfg($vRouter);


print ">>> Remove '$vRouter->{name}' NETCONF node from the Controller\n";
$status = $bvc->delete_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "'$vRouter->{name}' NETCONF node was successfully removed from the Controller\n\n";


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");


sub show_vpn_cfg {
    my $vRouter = shift;

    print "<<< Show vpn configuration on the '$vRouter->{name}'\n";
    my ($status, $vpncfg) = $vRouter->get_vpn_cfg();
    if ($status->no_data) {
	print "No VPN configuration found.\n\n";
	return;
    }
    $status->ok or
        $bvc->delete_netconf_node($vRouter) and
        die "!!! Demo terminated, reason: ${\$status->msg}\n";
    print "'$vRouter->{name}' VPN configuration:\n";
    print JSON->new->canonical->pretty->encode(JSON::decode_json($vpncfg))
        . "\n";
}

