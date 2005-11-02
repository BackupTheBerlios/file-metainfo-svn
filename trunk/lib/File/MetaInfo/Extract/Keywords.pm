#!/usr/bin/perl
use strict;

package File::MetaInfo::Extract::Keywords;
use base qw(File::MetaInfo::Extract);

use File::MetaInfo::Utils;
#use AutoLoader;
#
my $packname = __PACKAGE__;
my $keywords_name="File::MetaInfo::Extract.keywords";

my @_extract_keywords;

sub dmsg{ return "*** DEBUG [$packname]: @_" }

sub new{
    my $this=shift;
    my $class=ref($this) || $this;
    my $filename=shift;
        
	my %self;
	my %options= @_;
	$self{cmd}="/usr/bin/extract";
	$self{debug}=0;
	$self{filename}=$filename;
	$self{cfg_ignorekeywords}=(
		"filename"
	);
	if ((! -r $filename) || (! -s $filename) ){
		$@='File read error';
		return undef;
	}
	@self{keys %options} = values %options;
	#$self{exclude}

        my $self = bless \%self, $class;
        return $self;
}

sub extract{
	my $self=shift;

	my %hash;
	my @out=`$self->{cmd} "$self->{filename}"`;
	my @list=undef;
	foreach my $l (@out){
		chomp $l;
		my ($key,$val)=split(/ - /,$l);
		my $oldkey=$key;
		$key=$packname . '.' . $key;
		if (defined($val) && ($val !~ /^$/) && defined($key) && ($self->{exclude} !~ /$key/)){
			if ($oldkey =~ /date/){
				warn dmsg "Before key=$oldkey val=$val" if ($self->{debug});
				File::MetaInfo::Utils::normalize_date(\$val);
				warn dmsg "Normalized key=$oldkey val=$val" if ($self->{debug});
			}
#			warn "extract: key=$key\tval=$val\n" if ($self->{debug});
			File::MetaInfo::Utils::normalize_string(\$val);
			my @vals=split(/ /,$val);
			push @{$hash{$key}},$val;
			push @{$hash{$keywords_name}},@vals;
			warn "extract: key=$key\tval=" . join(',',@{$hash{$key}}) . "\n" if ($self->{debug});
		}
	}
	return \%hash;
}

sub test{
	my $fn=shift;
	use Data::Dumper;
	print "File::MetaInfo::Extract::Keywords test method.\n";
	print "\tCreating new object from file \"$fn\":\n";
	my $e = File::MetaInfo::Extract::Keywords->new($fn, debug => 0, exclude => 'filename' ) || die "$@";
	print "\t\t". Dumper($e);
	print "\tExtracting keywords:\n";
	my $href = $e->extract;
	print "\t\t" . Dumper($href);
}

1
