#!/usr/bin/perl

use strict;
use Data::Dumper;
use Sys::Filesystem;

my $fs = new Sys::Filesystem;

my @filesystems=$fs->filesystems();
print Dumper(\@filesystems);
print Dumper($fs);
