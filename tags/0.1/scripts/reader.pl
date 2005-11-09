#!/usr/bin/perl

open (PIPE,"< /tmp/FileInfoSearchService");

while (<PIPE>){
	print "$_\n";
}
