#!/usr/bin/perl

use strict;
use FileInfo::DB;
use Getopt::Long;
use Time::HiRes;
use FileInfo::Keyword::Extract;

my $debug;
my $measure;

GetOptions(
	"debug" => \$debug,
	"measure" => \$measure
);

my $fileInfoDB=new FileInfo::DB ( 
	debug => $debug,
	measure => $measure
);
my $arrayref=$fileInfoDB->get_files_id() || die "No row returned";
print "arrayref: @$arrayref\n";
my $ret=$fileInfoDB->enqueue_files($arrayref);
print "ret=$ret\n";

$fileInfoDB->close();
