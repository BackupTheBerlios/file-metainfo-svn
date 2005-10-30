#!/usr/bin/perl
use strict;

package File::MetaInfo::Extract::MimeType;
use base qw(File::MetaInfo::Extract);

use Digest::MD5;
use Data::Dumper;

my $packname = __PACKAGE__;
my $keyword=$packname . ".mimetype";

sub new{
	my $this=shift;
	my $class=ref($this) || $this;
	my $filename=shift;

    	my %self;
    	my %options=@_;
	$self{debug}=0;
	$self{filename}=$filename;
	
	return undef unless (-f $filename);
    
	@self{keys %options} = values %options;
	
	my $self = bless \%self, $class;
    return $self;
}

sub extract{
	my $self=shift;
	my $filename=shift || $self->{filename};
	my %hash;

	my $ret=`/usr/bin/file -i "$filename"`;
     
	if (!defined($ret)){
    		warn "WARNING: Error opening file $filename: $!";
    		return undef
    	}
	my (undef,$mimetype)=split(': ',$ret);
	return undef unless $mimetype;
	chomp $mimetype;
	warn "DEBUG: filename: $filename mimetype: $mimetype" if ($self->{debug});
	push @{$hash{$keyword}},$mimetype;
	
	warn "DEBUG: " . Dumper(\%hash) if ($self->{debug});
	
	return \%hash;
}

sub test{
	my $filename=shift;
	my $mimetest=new File::MetaInfo::Extract::MimeType($filename);
	my $h=$mimetest->extract();
	print Dumper($h);
}


