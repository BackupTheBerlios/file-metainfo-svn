#!/usr/bin/perl
use strict;

package FileInfo::Plugins::MD5;
use base qw(FileInfo::Plugins);

use Digest::MD5;
use Data::Dumper;

my $EMPTY="1B2M2Y8AsgTpgAmY7PhCfg";

my $packname = __PACKAGE__;
my $keyword=$packname . ".md5";

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
	my %hash;

    my $ret=open(FILE,$self->{filename});
     
    if (!defined($ret)){
    	warn "WARNING: Error opening file $self->{filename}: $!";
    	return undef
    }
    warn "MD5->{filename}: $self->{filename}" if ($self->{debug});
    	my $file=Digest::MD5->new->addfile(*FILE);
	my $digest=$file->b64digest || warn "Could not compute Digest for $self->{filename} $! $@";

	push @{$hash{$keyword}},$digest;
	
	warn "DEBUG: " . Dumper(\%hash) if ($self->{debug});
	
	return \%hash;
}

sub test{
	my $filename=shift;
	my $md5test=new FileInfo::Plugins::MD5($filename);
	my $h=$md5test->extract();
	print Dumper($h);
}


