#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Gnome2::VFS;

my $fn=$ARGV[0];
print "#$fn\n";
if (defined($fn) && -f $fn){
	Gnome2::VFS->init() || die "Initializing GNOME VFS: $!";

	my $gfh=Gnome2::VFS->open($fn,"read") || die "opening file $fn: $!";
	print "Gnome2::VFS->open($fn) = $gfh \n";
	my ($res,$info)=$gfh->get_file_info("default");
	print "$fn\n";
	print $info->{name} . "\n";
	print $info->{size} . "\n";
	print $info->get_mime_type() . "\n";
  
	my $result = $gfh -> close();
	Gnome2::VFS -> shutdown();
}
