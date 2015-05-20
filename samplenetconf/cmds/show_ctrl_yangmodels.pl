#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new BVC::Controller($configfile);

my ($status, $schemas) = $bvc->get_schemas('controller-config');
$status->ok or die "Error: ${\$status->msg}\n";

print "YANG models list:\n";
print JSON->new->canonical->pretty->encode($schemas);

