#!/usr/bin/perl

package FileInfo::Shell;

use strict;
use FileInfo::DB;
use FileInfo;
use Term::ReadLine;
use Cwd 'abs_path';
use Data::Dumper;

our $debug=0;

my %command=(
	'ls' => \&ls,
	'info' => \&info,
	'fi' => \&info,
	'open' => \&openFileInfo,
	'label' => \&add_label,
	'search' => \&search,
	'labels' => \&list_keywords,
	'll' => \&list_keywords,
);

my $fdb=new FileInfo::DB( debug => $debug ) || die "Could not open db";
my $filename;
my $fileID;
my $fi;
my $term = new Term::ReadLine 'FileInfo::Shell';
my $OUT = $term->OUT || \*STDOUT;
my %openfiles;
my $ltype='user_label';

sub shell{
	my $prompt0 = "FileInfo::Shell";
	my $prompt = $prompt0 . "> ";
	
	while ( defined ($_ = $term->readline($prompt)) ) {
		my $ret="";
		my $k=undef;
		chomp $_;
		print $OUT "DEBUG: cmd=$_\n" if $debug;
		#Spacial commands
		if (/^quit$/ || /^q$/){
			return
		}
		elsif (/^debug$/){
			print $OUT "Commands: ". Dumper(\%command) . "\n";
			print $OUT "Open files: ". Dumper(\%openfiles) . "\n";
		}
		elsif (/^(\w*)\s*(.*)$/g){
			print $OUT "DEBUG: processing command \'$1/$2\'\n" if $debug;
			if(defined($2)){
				$k=$2
			}
			if (!defined($command{$1})){
			  print $OUT "Error: no such command\n";
		  	}
			else {
			  eval {
			    print $OUT "DEBUG: running $command{$1}($2)\n" if $debug;
			    $ret=>$command{$1}($k);
		    	  }; print $OUT $@ if $@;
		  }
		}
		$term->addhistory($_) if /\S/;
	}
}


sub print_it{
	my $func=shift;
}

sub openFileInfo{
	my $f=shift || undef;

	return undef unless defined($f);
	my $fi=new FileInfo(
                $f,
		fileInfoDB=>$fdb,
                debug=>$debug
        );
	if (!defined($fi)){
		print $OUT "Warning: file not opened\n";
		return undef;
	}
	$openfiles{$fi->{id}}=$fi;
	return 0;
}

sub info{
	my $fid=shift || undef;
	return undef unless defined($fid);
	
	if (!defined($openfiles{$fid})){
		print $OUT "Warning: file not open, opening...";
		openFileInfo($fid);
		print $OUT "done\n";
	}

	$openfiles{$fid}->print_info(undef,undef,$OUT);
	return 0;
}

sub ls{
	my $k=shift || undef;
	
	print $OUT "DEBUG: lsk ($k)\n" if $debug;

	my $aref;
	if (!defined($k)){
		$aref=$fdb->list_all_keywords();
	}
	elsif ($k =~ /^(.*)=(.*)$/g){
		$aref=$fdb->list_files_by_keyword(undef,$1,$2);
	}
	else{
		$aref=$fdb->list_all_values_for_keyword($k);
	}
	return unless ($aref);
	foreach my $j (@{$aref}){
		print $OUT $j->[0] . "\n";
	}
}

sub list_keywords{
	my $fid=shift || undef;
	if(!defined($fid)){
		print $OUT "You must specify a fileID.\n";
		return undef
	}
	
	if (!defined($openfiles{$fid})){
		print $OUT "Warning: file not open, opening...";
		openFileInfo($fid);
		print $OUT "done\n";
	}

	$openfiles{$fid}->print_values();
	return 0;
}

sub add_label{
	my $fid=shift;
	my $label=shift;

	if (!defined($openfiles{$fid})){
		print $OUT "Warning: file not open, opening...";
		openFileInfo($fid);
		print $OUT "done\n";
	}
	print $OUT "Adding keyword $ltype=$label\n";
	return $openfiles{$fid}->add_keyword($ltype,$label);
}

sub search{
}



1
