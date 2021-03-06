#!/usr/bin/perl 

use strict;

use Getopt::Long;
use Carp;
use Data::Dumper;
use lib $ENV{FILEMETAINFO_LIBDIR};
use File::MetaInfo;

my $debug=0;
my $m=0;
my $gnome;
my $opt_l;
my ($tf,$t0);

GetOptions(
	"debug" => \$debug,
	"measure" => \$m,
	"gnome" => \$gnome,
	"long" => \$opt_l,
);

my $fn=shift;
if (!defined($fn)){
	warn "Usage: $0 filename - query the FileMetaInfoDB for informations about the specified file\n";
	die "Missing filename\n";
}
while ($fn){;
if ($m){
	use Time::HiRes
}

$t0=Time::HiRes::time if ($m);

my $fi=new File::MetaInfo(
		$fn,
		debug=>$debug,
		measure=>$m
	);

$tf=Time::HiRes::time if ($m);
carp "TIMES: File::MetaInfo->new(\"$fn\") takes " . ($tf-$t0) . " seconds" if ($m);

$t0=Time::HiRes::time if ($m);

if ($opt_l){
	print "File Info:\n";
	$fi->print_info();
}
else {
	print $fi->{fullpath} . " ";
}

$tf=Time::HiRes::time if ($m);
carp "TIMES: File::MetaInfo->print_info() takes " . ($tf-$t0) . " seconds" if ($m);

$t0=Time::HiRes::time if ($m);
if ($opt_l){
	print "Keywords:\n";

	$fi->print_values();

}
else {
	$fi->print_values("="," ",",",1);
	print "\n";
}
$tf=Time::HiRes::time if ($m);
carp "TIMES: File::MetaInfo->print_values() takes " . ($tf-$t0) . " seconds" if ($m);


if($gnome){
	$t0=Time::HiRes::time if ($m);
	my $vfs_info=$fi->refresh_vfsinfo();
	carp "TIMES: File::MetaInfo->get_vfs_info() takes " . ($tf-$t0) . " seconds" if ($m);
	$fi->print_gnome2_info();
}
$tf=Time::HiRes::time if ($m);

warn Dumper($fi) if $debug;

$fi->close();
$fn=shift;
}
