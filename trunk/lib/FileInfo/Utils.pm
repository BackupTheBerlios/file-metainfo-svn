#!/usr/bin/perl

package FileInfo::Utils;

use strict;
use Time::HiRes;

my $myname=__PACKAGE__;
our $debug=0;

sub dmsg{ return "*** DEBUG [$myname]: @_" };

sub start_timer{
	return Time::HiRes::time;
}

sub stop_timer{
	my $t0=shift;
	if (!defined($t0)){
		warn "Fatal: FileInfo::Utils you must provide a timer";
		return undef;
	}
	my $tf=Time::HiRes::time;
	return ($tf-$t0);
}

sub normalize_string{
	my $string=shift;
	warn dmsg "Initial string: \[${$string}\]" if ($debug);
	# Removes initial and ending blanks, multi-blanks, and non-word characters
	${$string} =~ s/^\W\W*//;
	${$string} =~ s/(\S)  *(\S)/$1 $2/;
	${$string} =~ s/(\S)\W\W*$/$1/;
	# Normalize case: simple way -> lowcase
	#if (${$string} =~ m/^([a-z])/){
	#	my $C=uc $1;
	#	${$string} =~ s/^[a-z]/$C/;
	#}
	${$string} =~ tr/A-Z/a-z/;
	warn dmsg "Result string: \[${$string}\]" if ($debug);
}

sub normalize_date{
	my $dateref=shift;
	if  (${$dateref} =~ /([0-9]*)-([0-9]*)-([0-9]*)[t,T]([0-9]*):([0-9]*):([0-9]*)/){
		${$dateref}="$1$2$3$4$5$6";
	}

}

1;
