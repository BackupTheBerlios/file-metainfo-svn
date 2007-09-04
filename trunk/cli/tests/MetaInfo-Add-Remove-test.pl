#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::Simple tests => 2;

use lib $ENV{FILEMETAINFO_LIBDIR};
use File::MetaInfo;

my $cwd=`pwd`;
chomp $cwd;
my $fn=shift || "$cwd/$0";
my $debug=shift || 0;

# Test 1: creation
print "$fn\n";
my $finfo=new File::MetaInfo(
	$fn,
	debug => $debug
);
ok ( defined $finfo, 'File::MetaInfo object creation');
if (!defined $finfo){
	warn "Error: $File::MetaInfo::err\n";
	exit 1;
}
warn Dumper($finfo) if $debug;

# Test 2: remove
my @ret=$finfo->remove();
ok (( ($ret[0] > 0) && ($ret[1] > 0)), 'File::MetaInfo object removed');
if (($ret[0] < 0) ||  ($ret[1] < 0)){
	warn "Error: $File::MetaInfo::err";
	exit 1
}
