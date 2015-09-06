#!/usr/bin/perl -T

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

use 5.006;
use strict;
use warnings;
use Test::More;

require File::Find;

my $Test = Test::Builder->new;

my $cfgfile = 'xt/bsc.yml';
my @demos   = _ctrl_demos();

# To run this test, create a file in the xt directory named ctrl.yml
# containing parameters for your local topology.  Example:
#
### # Controller specification
### ctrlIpAddr: "172.22.19.67"
### ctrlPortNum: "8181"
### ctrlUname: 'admin'
### ctrlPswd:  'admin'
###
### # Node specification
### nodeName: "lwp-vr-5600"
### nodeIpAddr: "172.22.17.71"
### nodePortNum: 830
### nodeUname: "vyatta"
### nodePswd: "vyatta"

-f $cfgfile or plan skip_all => "create $cfgfile to run ctrl_demo tests";

$Test->plan(tests => scalar @demos);

local $ENV{PATH} = "/bin:/usr/bin";
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
local $ENV{PERL5LIB} = "$ENV{PWD}/lib";

foreach my $demo (@demos) {
    $demo =~ /ctrl_demo10/ && $Test->skip('TODO: fix ctrl_demo10') && next;
    # untaint *cough*
    $demo =~ m[(../samples/netconf/demos/ctrl_demo\d+.pl$)]g && ($demo = $1);
    my $ok = (0 == system ("$demo -c $cfgfile"));
    $Test->ok($ok, $demo);
}

sub _ctrl_demos {
    my @demos;
    File::Find::find({
            wanted => sub {
                -f $_
                  && $_ =~ /.*ctrl.*\.pl$/
                  && push @demos, $_;
            },
            no_chdir => 1,
        },
        '../samples/netconf/demos'
    );

    return @demos;
}
