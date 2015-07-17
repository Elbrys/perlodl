#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Brocade::BSC;

my $configfile = "";

GetOptions("config=s" => \$configfile) or die ("Command line args");

my $bvc = new Brocade::BSC($configfile);

my ($status, $schemas) = $bvc->get_schemas('controller-config');
$status->ok or die "Error: ${\$status->msg}\n";

print "YANG models list:\n";
print JSON->new->canonical->pretty->encode($schemas);

