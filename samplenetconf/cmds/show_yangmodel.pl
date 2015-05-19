#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use BVC::Controller;
use BVC::Netconf::Vrouter::VR5600;

my $configfile  = undef;
my $yangId      = undef;
my $yangVersion = undef;

GetOptions("config=s"     => \$configfile,
           "identifier=s" => \$yangId,
           "version=s"    => \$yangVersion
    ) or die ("Command line args");

($yangId && $yangVersion)
    or die "identifier and version arguments are required.";

my $bvc = new BVC::Controller(cfgfile => $configfile);
my $vRouter = new BVC::Netconf::Vrouter::VR5600(cfgfile => $configfile,
                                                ctrl => $bvc);

print "<<< 'Controller': $bvc->{ipAddr}, " .
    "'$vRouter->{name}': $vRouter->{ipAddr}\n";

my ($status, $schema) = $vRouter->get_schema($yangId, $yangVersion);
$status->ok or die "Error: ${\$status->msg}\n";

print $schema . "\n";
