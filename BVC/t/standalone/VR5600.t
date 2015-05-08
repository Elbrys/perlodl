#!/usr/bin/perl -T

use Test::More tests => 15;

# check module load 1
use_ok( 'BVC::Netconf::Vrouter::VR5600' );
use BVC::Netconf::Vrouter::VR5600;
use BVC::Controller;

# create object with specified values 10
my $bvc = new BVC::Controller;
my $vRouter = new BVC::Netconf::Vrouter::VR5600(ctrl => $bvc,
                                                name => 'vr5600',
                                                ipAddr => '192.168.99.4',
                                                adminName => 'vyatta',
                                                adminPassword => 'Vy@tt@');

ok( defined($vRouter),                            "created VR5600 object");
ok( $vRouter->isa(BVC::Netconf::Vrouter::VR5600), "...and its a VR5600");
is( scalar keys %$vRouter, 7,                     "   a HASH with seven keys");
ok( $vRouter->{ctrl}->isa(BVC::Controller),       "controller object (specified)");
is( $vRouter->{name}, 'vr5600',                   "name (specified)");
is( $vRouter->{ipAddr}, '192.168.99.4',           "ipAddr (specified)");
is( $vRouter->{portNum}, 830,                     "portNum (default)");
is( $vRouter->{tcpOnly}, 0,                       "tcpOnly (default)");
is( $vRouter->{adminName}, 'vyatta',              "adminName (specified)");
is( $vRouter->{adminPassword}, 'Vy@tt@',          "adminPassword (specified)");

# verify methods accessible 4
# inherited
can_ok( $vRouter, as_json );
# self
can_ok( $vRouter, get_schema );
can_ok( $vRouter, get_cfg );
can_ok( $vRouter, get_interfaces_list );
