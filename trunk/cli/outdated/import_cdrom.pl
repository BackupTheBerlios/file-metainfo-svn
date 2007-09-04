#!/usr/bin/perl

use strict;
use Cwd qw(abs_path);
use Getopt::Long;
use Carp;
use File::Basename;
use File::Find;
use FileInfo::DB;
use FileInfo;
use Time::HiRes;
use Data::Dumper;

use lib "/home/developement/glocate";

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

my $fdb=new FileInfo::DB( debug=> $debug);

$basedir || die "FATAL: You must specify the --base-directory\n";

$basedir=abs_path($basedir);
warn "DEBUG: basedir=$basedir\n" if $debug;
$i=0;
print "Importing $basedir\n";
my $t0=Time::HiRes::time;
find(\&add_it, $basedir);
print "\nProcessed $i files ";
my $tf=Time::HiRes::time;
my $time=($tf - $t0);
print "\nDone: processed $i files in $time \n";
my $t0=Time::HiRes::time;

my $dbfn=$fdb->get_dbfilename();
$fdb->close();
my $size=`du -k $dbfn | cut -f 1`;
print "*** Stats ***\n";
print "Totals:\n";
print "$i;$time;$size\n";


#############
#
sub add_it{
	warn "DEBUG: main::add_it::filename=$File::Find::name\n" if $debug;
	my $fn=$File::Find::name;
	my $finfo=new FileInfo(
			$fn,
			fileInfoDB=>$fdb,
			debug=>$debug
			) || die;
	$finfo->update_keywords();
	$i++;
	print ".";
}

