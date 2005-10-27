#!/usr/bin/perl

use strict;
use Getopt::Long;
use FileInfo;

my $ret=0;
my $force=0;
my $debug;

GetOptions(
	"force", \$force,
	"debug", \$debug
);

if (!defined($ARGV[0])){
	warn "Usage: $0 filename - query the FileInfoDB for informations about the specified file\n";
	die "Missing filename\n";
}

my $fi=new FileInfo(
		$ARGV[0],
		debug=>$debug
	);

print "File Info:\n";
$fi->print_info();
if ( $fi->changed() || $force ){
	print "File needs to be updated!!\n";
	$fi->update();
}
$fi->close();
exit $ret;
