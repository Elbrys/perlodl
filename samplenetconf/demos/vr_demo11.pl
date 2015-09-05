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
use Brocade::BSC::Node::NC::Vrouter::VPN;

my $configfile = "";
my $status     = undef;

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bsc = Brocade::BSC->new(cfgfile => $configfile);
my $vRouter = Brocade::BSC::Node::NC::Vrouter::VR5600->new(
    cfgfile => $configfile,
    ctrl    => $bsc
);

print "<<< 'Controller': $bsc->{ipAddr}, '"
  . "$vRouter->{name}': $vRouter->{ipAddr}\n\n";


$status = $bsc->add_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' added to the Controller\n\n";
sleep (2);


$status = $bsc->check_node_conn_status($vRouter->{name});
$status->connected or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print "<<< '$vRouter->{name}' is connected to the Controller\n\n";


show_vpn_cfg($vRouter);


print ">>> Create new VPN configuration on '$vRouter->{name}'\n\n";
print " NOTE: For this demo to succeed the local RSA key must exist on ";
print "the '$vRouter-{name}'\n";
print "       (use the 'generate vpn rsa-key' command to create it)\n\n";

my $vpn       = Brocade::BSC::Node::NC::Vrouter::VPN->new();
my $ike_group = 'IKE-1W';
my $esp_group = 'ESP-1W';

$vpn->set_ipsec_ike_group_proposal(
    group      => $ike_group,
    tagnode    => 1,
    encryption => 'aes256',
    hash       => 'sha1'
);
$vpn->set_ipsec_ike_group_proposal(
    group      => $ike_group,
    tagnode    => 2,
    encryption => 'aes128',
    hash       => 'sha1'
);
$vpn->set_ipsec_ike_group_lifetime(
    group    => $ike_group,
    lifetime => 3600
);


$vpn->set_ipsec_esp_group_proposal(
    group      => $esp_group,
    tagnode    => 1,
    encryption => 'aes256',
    hash       => 'sha1'
);
$vpn->set_ipsec_esp_group_proposal(
    group      => $esp_group,
    tagnode    => 2,
    encryption => '3des',
    hash       => 'md5'
);
$vpn->set_ipsec_esp_group_lifetime(
    group    => $esp_group,
    lifetime => 1800
);

#-------------------------------------------------------------------------
# Configure connection to a remote peer
#-------------------------------------------------------------------------

my $peer = '192.0.2.33';
$vpn->ipsec_site_site_peer_description($peer,
'Site-to-Site VPN Configuration Example - RSA Digital Signature Authentication'
);

$vpn->ipsec_site_site_peer_auth_mode($peer, 'rsa');
my $rsa_key_name = 'EAST-PEER-key';
my $rsa_key =
    '0sAQOVBIJL+rIkpTuwh8FPeceAF0bhgLr++W51bOAIjFbRDbR8gX3Vlz6wiU'
  . 'bMgGwQxWlYQiqsCeacicsfZx/amlEn9PkSE4e7tqK/JQo40L5C7gcNM24mup'
  . '1d+0WmN3zLb9Qhmq5q3pNJxEwnVbPPQeIdZMJxnb1+lA8DPC3SIxJM/3at1/'
  . 'KrwqCAhX3QNFY/zNmOtFogELCeyl4+d54wQljA+3dwFAQ4bboJ7YIDs+rqOR'
  . 'xWd3l3I7IajT/pLrwr5eZ8OA9NtAedbMiCwxyuyUbznxXZ8Z/MAi3xjL1pjY'
  . 'yWjNNiOij82QJfMOrjoXVCfcPn96ZN+Jqk+KknoVeNDwzpoahFOseJREeXzk'
  . 'w3/lkMN9N1';
$vpn->rsa_key(
    name  => $rsa_key_name,
    value => $rsa_key
);
$vpn->ipsec_site_site_peer_auth_rsa_key_name($peer, $rsa_key_name);

$vpn->ipsec_site_site_peer_dflt_esp_grp($peer, $esp_group);
$vpn->ipsec_site_site_peer_ike_grp($peer, $ike_group);

$vpn->ipsec_site_site_peer_local_addr($peer, '192.0.2.1');
$vpn->ipsec_site_site_peer_tunnel_local_pfx(
    peer   => $peer,
    tunnel => 1,
    subnet => '192.168.40.0/24'
);
$vpn->ipsec_site_site_peer_tunnel_remote_pfx(
    peer   => $peer,
    tunnel => 1,
    subnet => '192.168.60.0/24'
);


print ">>> VPN configuration to be applied to the '$vRouter->{name}'\n";
print $vpn->get_payload() . "\n\n";

$status = $vRouter->set_vpn_cfg($vpn);
$status->ok
  or $bsc->delete_netconf_node($vRouter)
  and die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "<<< VPN configuration was successfully created.\n\n";


show_vpn_cfg($vRouter);


print "<<< Delete VPN configuration on the '$vRouter->{name}'\n";
$status = $vRouter->delete_vpn_cfg();
$status->ok
  or $bsc->delete_netconf_node($vRouter)
  and die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "VPN configuration successfully removed from '$vRouter->{name}'\n\n";


show_vpn_cfg($vRouter);


print ">>> Remove '$vRouter->{name}' NETCONF node from the Controller\n";
$status = $bsc->delete_netconf_node($vRouter);
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";
print
"'$vRouter->{name}' NETCONF node was successfully removed from the Controller\n\n";


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
    $status->ok
      or $bsc->delete_netconf_node($vRouter)
      and die "!!! Demo terminated, reason: ${\$status->msg}\n";
    print "'$vRouter->{name}' VPN configuration:\n";
    print JSON->new->canonical->pretty->encode(JSON::decode_json($vpncfg))
      . "\n";
    return;
}

