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
use Brocade::BSC::Node::OF::Switch;

my $configfile = "";
my $status = undef;
my $switch_info = undef;
my $features = undef;
my $portlist = undef;
my $portinfo = undef;

my $sample = "openflow:1";

GetOptions("config=s" => \$configfile) or die ("Command line args");

print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
print ("<<< Demo Start\n");
print ("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n");

my $bvc = new Brocade::BSC(cfgfile => $configfile);
print "'Controller':\n";
print $bvc->as_json() . "\n";
my $ofswitch = new Brocade::BSC::Node::OF::Switch(ctrl => $bvc, name => $sample);

    
print "<<< Get information about OpenFlow node '$sample'\n";
($status, $switch_info) = $ofswitch->get_switch_info();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Node '$sample' generic info:\n";
print JSON->new->canonical->pretty->encode($switch_info) . "\n";


($status, $features) = $ofswitch->get_features_info();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Node '$sample' features:\n";
print JSON->new->canonical->pretty->encode($features) . "\n";


($status, $portlist) = $ofswitch->get_ports_list();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Node '$sample' ports list:\n";
print JSON->new->canonical->pretty->encode($portlist) . "\n";


($status, $portinfo) = $ofswitch->get_ports_brief_info();
$status->ok or die "!!! Demo terminated, reason: ${\$status->msg}\n";

print "Node '$sample' ports brief information:\n";
print JSON->new->canonical->pretty->encode($portinfo);


print ("\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
print (">>> Demo End\n");
print (">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
