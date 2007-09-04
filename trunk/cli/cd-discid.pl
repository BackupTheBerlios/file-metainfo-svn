#!/usr/bin/perl

use strict;
use Data::Dumper;
use VolumeInfo::CD qw(get_discids);

if ($#ARGV < 0){
	warn "Usage: cd-discid.pl <devicename>\n";
	exit 1;
}

my $device=VolumeInfo::CD::real_device($ARGV[0]);
my $status=VolumeInfo::CD::is_mounted($device);
my $mp=VolumeInfo::CD::mount_point($device);
#print Dumper(VolumeInfo::CD::_info($device);

print "# CD device " . $device ;
if ($status){
	print " is"
}
else {
	print " should be"
}
print " mounted at $mp. #\n";

my ($id,$last,$lenght,$toc)=VolumeInfo::CD::get_discids($device);

print "$id $last ";
my $i=0;
for ($i=0; $i < $last; $i++){
	print "$toc->[$i]->{frames} ";
}
print "$lenght\n";


