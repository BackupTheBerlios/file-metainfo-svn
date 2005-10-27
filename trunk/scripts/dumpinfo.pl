#!/usr/bin/perl -I /home/developement/FileInfo/lib

use strict;
use Getopt::Long;
use FileInfo;
use Carp;
use Data::Dumper;

my $debug=0;
my $m=0;
my $gnome;
my ($tf,$t0);

GetOptions(
	"debug" => \$debug,
	"measure" => \$m,
	"gnome" => \$gnome
);

my $fn=shift;
if (!defined($fn)){
	warn "Usage: $0 filename - query the FileInfoDB for informations about the specified file\n";
	die "Missing filename\n";
}
if ($m){
	use Time::HiRes
}

$t0=Time::HiRes::time if ($m);

my $fi=new FileInfo(
		$fn,
		debug=>$debug,
		measure=>$m
	);

$tf=Time::HiRes::time if ($m);
carp "TIMES: FileInfo->new(\"$fn\") takes " . ($tf-$t0) . " seconds" if ($m);

$t0=Time::HiRes::time if ($m);

$tf=Time::HiRes::time if ($m);
carp "TIMES: FileInfo->print_values() takes " . ($tf-$t0) . " seconds" if ($m);

if($gnome){
	$t0=Time::HiRes::time if ($m);
	my $vfs_info=$fi->refresh_vfsinfo();
	carp "TIMES: FileInfo->refresh_vfsinfo() takes " . ($tf-$t0) . " seconds" if ($m);
}
$tf=Time::HiRes::time if ($m);

my $dumper= Data::Dumper->new([$fi],[qw(FileInfo)]);
print $dumper->Dump;

$fi->close();
