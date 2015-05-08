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

#!/usr/bin/perl -T

use Test::More tests => 20;

# check module load 1
use_ok( 'BVC::Controller' );
use BVC::Controller;

# create object with default values 8
my $bvc = new BVC::Controller;
ok( defined($bvc),              "created Controller object" );
ok( $bvc->isa(BVC::Controller),  "...and it's a Controller object" );
is( scalar keys %$bvc, 5,        "    a HASH with five keys" );
is( $bvc->{ipAddr}, '127.0.0.1',   "default ipAddr, localhost");
is( $bvc->{portNum}, 8181,         "default tcp port");
is( $bvc->{adminName}, 'admin',    "default adminName");
is( $bvc->{adminPassword}, 'admin', "default adminPassword");
is( $bvc->{timeout}, 5,             "default timeout");

# create object with some specified values 7
my $bvc2 = new BVC::Controller(ipAddr => '192.168.99.3',
                               adminName => 'testuser',
                               adminPassword => '$3cr3t');
ok( defined($bvc2),                   "created Controller object with parameters");
ok( $bvc2->isa(BVC::Controller),      "...and it's a Controller object");
is( $bvc2->{ipAddr}, '192.168.99.3',  "ipAddr (specified)");
is( $bvc2->{portNum}, '8181',         "tcp port (default)");
is( $bvc2->{adminName}, 'testuser',   "adminName (specified)");
is( $bvc2->{adminPassword}, '$3cr3t', "adminPassword (specified)");
is( $bvc2->{timeout}, 5,              "timeout (default)");

# verify methods accessible 4
can_ok( $bvc, as_json );
can_ok( $bvc, get_nodes_operational_list );
can_ok( $bvc, get_node_info );
can_ok( $bvc, check_node_config_status );
