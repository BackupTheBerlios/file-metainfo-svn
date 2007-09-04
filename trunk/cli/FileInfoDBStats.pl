#!/usr/bin/perl

use strict;
use FileInfo::DB;

my $fidb=new FileInfo::DB( debug => 0);

my $stats_hashref=$fidb->stats();

print "FileInfo DB: " . $fidb->get_dbfilename . "\n";
foreach my $k (keys %$stats_hashref){
	print "\t$k: $stats_hashref->{$k}\n";
}

$fidb->close();
