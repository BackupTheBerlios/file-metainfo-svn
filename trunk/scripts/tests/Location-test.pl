#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::Simple tests => 1;

use lib $ENV{FILEMETAINFO_LIBDIR};
use File::MetaInfo::Location;

my $location=shift || "/var/tmp";
my $debug=shift || 0;

# Test 1: creation
my $fmil=new File::MetaInfo::Location(
	$location,
	debug => $debug
);
ok ( defined $fmil, 'File::MetaInfo::Location object creation');
if (!defined $fmil){
	warn "Error: $File::MetaInfo::Location::err\n";
	exit 1;
}
warn Dumper($fmil) if $debug;

# Test 2: 
