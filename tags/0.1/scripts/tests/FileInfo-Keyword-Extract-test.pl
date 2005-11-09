#!/usr/bin/perl

use strict;
use FileInfo::Keyword::Extract;

my $e = new  FileInfo::Keyword::Extract( debug => 1);

my %keys=$e->extract("$ARGV[0]");

print "$ARGV[0]\n";
foreach my $k (keys(%keys)){
	my @t=$keys{$k};
	print "#$k\t#@{$keys{$k}}\n";
}
