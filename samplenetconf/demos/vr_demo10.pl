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


show_vpn_cfg($vRouter);


print ">>> Create new VPN configuration on '$vRouter->{name}'\n\n";

my $vpn = new Brocade::BSC::Node::NC::Vrouter::VPN();
my $ike_group = 'IKE-1W';
my $esp_group = 'ESP-1W';

$vpn->set_ipsec_ike_group_proposal(group      => $ike_group,
                                   tagnode    => 1,
                                   encryption => 'aes256',
                                   hash       => 'sha1');
$vpn->set_ipsec_ike_group_proposal(group      => $ike_group,
                                   tagnode    => 2,
                                   encryption => 'aes128',
                                   hash       => 'sha1');
$vpn->set_ipsec_ike_group_lifetime(group      => $ike_group,
                                   lifetime   => 3600);


$vpn->set_ipsec_esp_group_proposal(group      => $esp_group,
                                   tagnode    => 1,
                                   encryption => 'aes256',
                                   hash       => 'sha1');
$vpn->set_ipsec_esp_group_proposal(group      => $esp_group,
                                   tagnode    => 2,
                                   encryption => '3des',
                                   hash       => 'md5');
$vpn->set_ipsec_esp_group_lifetime(group      => $esp_group,
                                   lifetime   => 1800);


my $peer = '192.0.2.33';
$vpn->ipsec_site_site_peer_description($peer, 'Site-to-Site VPN Configuration Example - Pre-Shared Key (PSK) Authentication');
$vpn->ipsec_site_site_peer_auth_mode   ($peer, 'pre-shared-secret');
$vpn->ipsec_site_site_peer_auth_psk    ($peer, 'test_key_1');
$vpn->ipsec_site_site_peer_dflt_esp_grp($peer, $esp_group);
$vpn->ipsec_site_site_peer_ike_grp     ($peer, $ike_group);
$vpn->ipsec_site_site_peer_local_addr  ($peer, '192.0.2.1');
$vpn->ipsec_site_site_peer_tunnel_local_pfx(peer   => $peer,
                                            tunnel => 1,
                                            subnet => '192.168.40.0/24');
$vpn->ipsec_site_site_peer_tunnel_remote_pfx(peer   => $peer,
                                             tunnel => 1,
                                             subnet => '192.168.60.0/24');


print ">>> VPN configuration to be applied to the '$vRouter->{name}'\n";
print $vpn->get_payload() . "\n\n";

$status = $vRouter->set_vpn_cfg($vpn);
$status->ok or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "<<< VPN configuration was successfully created.\n\n";


show_vpn_cfg($vRouter);


print "<<< Delete VPN configuration on the '$vRouter->{name}'\n";
$status = $vRouter->delete_vpn_cfg();
$status->ok or
    $bsc->delete_netconf_node($vRouter) and
    die "!!!Demo terminated, reason: ${\$status->msg}\n";
print "VPN configuration successfully removed from '$vRouter->{name}'\n\n";


show_vpn_cfg($vRouter);


print ">>> Remove '$vRouter->{name}' NETCONF node from the Controller\n";
$status = $bsc->delete_netconf_node($vRouter);
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
        $bsc->delete_netconf_node($vRouter) and
        die "!!! Demo terminated, reason: ${\$status->msg}\n";
    print "'$vRouter->{name}' VPN configuration:\n";
    print JSON->new->canonical->pretty->encode(JSON::decode_json($vpncfg))
        . "\n";
}

