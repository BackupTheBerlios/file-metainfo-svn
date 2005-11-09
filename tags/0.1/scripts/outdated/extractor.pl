#!/usr/bin/perl 

use strict;
use Getopt::Long;
use Carp;
use FileInfo::DB;

my ($debug,$measure);

GetOptions(
	"debug" => \$debug,
	"measure" => \$measure
);

my $fileInfoDB=new FileInfo::DB ( 
	debug => $debug,
	measure => $measure
);

if ($debug){
	use Data::Dumper
}




sub extract_keywords{	
	my $filename=shift;
	my $plugins=$fileInfoDB->list_plugins();
	warn Dumper($plugins) if $debug;
	foreach my $k (@$plugins){
		my $class = $k->[0];
		warn "Class: $class\n" if $debug;
		eval "require $class";
		my $p=$class->new($filename);
		my $e=$p->extract();
		warn Dumper ($e) if $debug;
	}
}