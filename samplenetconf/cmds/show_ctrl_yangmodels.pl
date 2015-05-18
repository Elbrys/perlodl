#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new BVC::Controller($configfile);

my ($status, $schemas) = $bvc->get_schemas('controller-config');

if ($status == $BVC_OK) {
    print "YANG models list:\n";
    print JSON->new->canonical->pretty->encode($schemas);
}
else {
    print "Error: " . $bvc->status_string($status) . "\n\n";
}
