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

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bsc = Brocade::BSC->new(cfgfile => $configfile);
my $ncNode =
  Brocade::BSC::Node::NC->new(cfgfile => $configfile, ctrl => $bsc);

print "<<< NETCONF nodes configured on the controller:\n\n";
my ($status, $nodes_ref) = $bsc->get_netconf_nodes_in_config();
$status->ok or die "Error: ${\$status->msg}\n";

foreach my $node (@$nodes_ref) {
    print "    '$node'\n";
}
print "\n";

print "<<< NETCONF nodes connection status on controller:\n\n";
($status, $nodes_ref) = $bsc->get_netconf_nodes_conn_status();
$status->ok or die "Error: ${\$status->msg}\n";

foreach my $node (@$nodes_ref) {
    my $connstatus = $node->{connected} ? "connected" : "not connected";
    print "    '$node->{id}' is $connstatus\n";
}
print "\n";
