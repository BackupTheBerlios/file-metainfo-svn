#!/usr/bin/perl

use strict;
use Cwd qw(abs_path);
use Getopt::Long;
use Carp;
use File::Basename;
use File::Find;
use FileInfo::DB;
use Time::HiRes;
use Data::Dumper;

my $debug;
my $measure;
my $basedir;
my @filelist;
my $i=0;
my $step=1000;
my $ret;

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

$basedir || die "FATAL: You must specify the --base-directory\n";

$basedir=abs_path($basedir);
warn "DEBUG: basedir=$basedir\n" if $debug;
$i=0;
print "Importing $basedir\n";
my $t0=Time::HiRes::time;
find(\&add_it, $basedir);
print "Processed $i files ";
my $rc=$fileInfoDB->add_files(\@filelist);
print "$rc files inserted now\n";
$ret+=$rc;
my $tf=Time::HiRes::time;

print "\nDone: processed $i files, $ret files inserted in " . ($tf - $t0) . "\n";

print "Now, enqueuing files for further processing\n";

my $t0=Time::HiRes::time;

my $arrayref=$fileInfoDB->get_files_id() || die "No row returned";

my $PluginsIDList=$fileInfoDB->get_plugin_id();

die "Cannot get list of plugins" if (!defined($PluginsIDList));
print "D: " . $PluginsIDList->[0] . "\n";
print Dumper($PluginsIDList);

my $ret=$fileInfoDB->enqueue_files($arrayref);
my $tf=Time::HiRes::time;
print "\nDone: processed $i files, $ret files inserted in " . ($tf - $t0) . "\n";

$fileInfoDB->close();


#############
#
sub add_it{
	warn "DEBUG: filename=$File::Find::name\n" if $debug;
	push @filelist, $File::Find::name;
	$i++;
	if ( ($i % $step) == 0){
		print "Processed $i files, ";
		my $r=$fileInfoDB->add_files(\@filelist);
		undef(@filelist);
		print "$r files inserted now\n";
		$ret+=$r;
	}
}

