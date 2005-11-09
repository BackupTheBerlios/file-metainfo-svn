#!/usr/bin/perl

use strict;
use Getopt::Long;
use FileInfo::DB;
use FileInfo::Search;
use Data::Dumper;
use Carp;

my $debug=0;
my $m=0;
my ($tf,$t0);

GetOptions(
        "debug" => \$debug,
        "measure" => \$m
);

my @args=@ARGV;

my $fdb=new FileInfo::DB( debug => $debug) || die "Could not open DB\n";

print "Querying for @args\n";
my $fileInfoSearch=new FileInfo::Search(
	\@args,
	fileInfoDB => $fdb,
	debug => $debug);

warn "DEBUG: fileInfoSearch=>" . Dumper($fileInfoSearch) if $debug;

my $array_ref=$fileInfoSearch->get_filesid();
print Dumper($array_ref);

$fileInfoSearch->close();
undef $fileInfoSearch;
$fdb->close();
undef $fdb;
