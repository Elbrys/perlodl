#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;

my $configfile  = undef;
my $yangId      = undef;
my $yangVersion = undef;

GetOptions("config=s"     => \$configfile,
           "identifier=s" => \$yangId,
           "version=s"    => \$yangVersion
    ) or die ("Command line args");

if (!$yangId || !$yangVersion) {
    die "identifier and version arguments are required.";
}

my $bvc = new BVC::Controller($configfile);

print "<<< 'Controller': " . $bvc->{ipAddr} . "\n";

my ($status, $schema) = $bvc->get_schema('controller-config',
                                         $yangId, $yangVersion);
if ($status == $BVC_OK) {
    print $schema . "\n";
}
else {
    die "Error: " . $bvc->status_string($status) . "\n";
}
