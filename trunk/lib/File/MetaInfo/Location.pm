#!/usr/bin/perl

use strict;
package File::MetaInfo::Location;

=head1 NAME

File::MetaInfo::Location - Class for locations in MetaInfo DB.

=head1 SYNOPSIS

 use File::MetaInfo::Location;
 my $fmil = new File::MetaInfo::Location("/usr/share/doc");

=head1 DESCRIPTION

This is an abstraction class for filesystems locations. It wraps the LOCATION table from the db. The table is defined as follows:

TABLE LOCATIONS (
	LOCATION VARCHAR,
	VOLUME CHAR(30),
	SCHEMA CHAR(10),
	HOST CHAR(100),
	LABEL VARCHAR(100),
	LASTUPDATE TIMESTAMP,
	DESCRIPTION TEXT,
	PRIMARY KEY (LOCATION, VOLUME)
)

=cut

our $NAME=__PACKAGE__;
our $VERSION="0.2";
our $err;

BEGIN {
	use Exporter();
	use vars qw($VERSION $NAME @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $err);
	$VERSION 	= "0.1";
	@ISA 		= qw (Exporter);
	@EXPORT		= qw ();
	@EXPORT_OK 	= qw ();
	%EXPORT_TAGS 	= ();
}


use Carp;
use File::MetaInfo::DB;

sub dmsg{ return "*** DEBUG [$NAME]: @_ " }
sub errmsg{ return "ERROR [$NAME]: @_ " }

=head1 CONSTRUCTORS

=head2 new

=cut

sub new {
	my $this=shift;
	my $class=ref($this) || $this;
	my %self;
	my $location=shift;
	my %options=@_;
	
	$self{location}="";
	$self{volume}="";
	$self{schema}="";
	$self{host}="";
	$self{label}="";
	$self{lastupdate}="";
	$self{description};
	$self{debug}=0;
	$self->{fstab_style}='linux';
	$self->{fstab}='/etc/fstab';
	
	@self{keys %options} = values %options;
	$self{debug}=0 if ($self{debug} lt 0);

	if ($self{measure}){
		use File::MetaInfo::Utils qw( start_timer stop_timer );
	}
	
	if ($self{debug}){
		use Data::Dumper;
	}

	#... code here...#
	
	warn dmsg "location: '$location'" if $self{debug};

	# 1. take the location and extract informations:
	# 	a. schema if not file (default schema is file://)
	# 	b. realpath if schema=file://
	# 	c. volume or media ID if not local filesystem
	my $uri;	
	if ($location =~ /(.*):\/\/(.*)/){
		# then it's an URI
		$self{schema}=$1;
		$uri=$2;
	}
	else{
		$self{schema}='file';
		$uri=$location;
	}
	warn dmsg "schema: '$self{schema}'" if $self{debug};
	warn dmsg "uri: '$uri'" if $self{debug};
	if ($self{schema} =~ /file/){
		use Cwd 'abs_path';

		$self{location}=abs_path($uri);
		$self{volume}=0;

		if ( ! -d $self{location}){
			$err="location does not exists";
			carp errmsg $err;
			return undef;
		}
		_identify_device($self{location},$self{fstab_style},$self{fstab},$self{debug});
	}
	else {
		$err="schema \'$self{schema}\' is not currently supported";
		carp errmsg $err;
		return undef;
	}
	

	warn Dumper(\%self) if $self{debug};
	
	#................#
	
	my $self = bless \%self, $class;
        return $self;
};

=head1 PUBLIC METHODS

=head2 save

Saves the object into the DB;

=cut

sub save{
	my $self=shift;
	my $db=shift || undef;

	$self->{MetaInfoDB}=$db;
    	if (!defined($self->{MetaInfoDB})){
    		warn dmsg "creating a new db connection" if $self->{debug};
		$self->{MetaInfoDB}=new File::MetaInfo::DB( debug => $self->{debug});
    	};
	$self->{MetaInfoDB}->add_location($self);
}

# private methods

sub _identify_device{
	my $location=shift;
	my $fstab_style=shift;
	my $fstab=shift;
	my $debug=shift;

	if ($fstab_style ne "linux"){
		$err="Currently only 'lunux' fstab style is supported";
		carp errmsg $err;
		return undef;
	}
	open(FSTAB,'<',	$fstab);

	my $best_match=undef;

	while (<FSTAB>){
		my ($spec,$file,$vfstype,$mntops,$freq,$passno);

		next if (/^ *#/ || /^$/);

		chomp;
		($spec,$file,$vfstype,$mntops,$freq,$passno)=split(/\s+|\t+/);

		if ($location =~ /$file/){
			if (!defined($best_match) || (length $file gt lenght $best_match[1])){
				@best_match=($spec,$file,$vfstype,$mntops,$freq,$passno);
			}
		}
	}
	warn dmesg "best_match: $best_match[1] $best_match[0]" if $debug;
	my @stats=stat $location;
	if ($stat[1] == 5632){
		warn dmesg "device is a CDROM";
		use File::MetaInfo::Volume::CD;

	}
}

1;
