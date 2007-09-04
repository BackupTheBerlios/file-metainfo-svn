#!/usr/bin/perl

use FileInfo::DB;
use Getopt::Long;

GetOptions(
	"debug" => \$debug,
	"measure" => \$measure,
	"base-directory=s" => \$basedir,
	"step=n" => \$step
);

my $fileInfoDB=new FileInfo::DB ( 
	debug => $debug,
	measure => $measure
);

$fileInfoDB->process_all_files(\&print_row);

sub print_row{
	my $rowref=shift;
	my $param=shift;
	#print "print_row\n";
	print "@$rowref\n";
}

$fileInfoDB->close();
