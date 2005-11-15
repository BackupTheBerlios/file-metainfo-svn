#!/usr/bin/perl

use strict;
use warnings;
package File::MetaInfo::Query::Simple;

our $NAME=__PACKAGE__;

use base qw(File::MetaInfo::Query);

use File::MetaInfo::DB;

use Carp;
use Data::Dumper;

our $debug=0;

BEGIN {
	use Exporter();
	use vars qw($VERSION $NAME @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $err);
	$VERSION 	= "0.1";
	@ISA 		= qw (Exporter File::MetaInfo::Query);
	@EXPORT		= qw ();
	@EXPORT_OK 	= qw ();
	%EXPORT_TAGS 	= ();
}

sub dmsg{ return "*** DEBUG [$NAME]: @_ " };

=head1 NAME

File::MetaInfo::Query::Simple - Implement OO interface to parse and query the File::MetaInfo::DB

=head1 SYNOPSIS

 use File::MetaInfo::Query::Simple;
 my $fmiq = File::MetaInfo::Query::Simple(
    'keyword:value',
    $options_hashref
 );

 $result=$fmiq->run();

=head1 DESCRIPTION

This module implement an OO interface to query the L<File::MetaInfo::DB> by creating a perl object.

=head1 PUBLIC METHODS

=head2 new

    $fmiq = File::MetaInfo::Query::Simple( $QUERY, %options );

Creates a new File::MetaInfo::Query::Simple object. The object is created by parsing the $QUERY string. Options can be specified thourgh $option_hashref. 
'$QUERY' is of the form [KEYWORD:]VALUE:

=over 4

=item * 

'KEYWORDS' is an optional argument and can be any of the indexed keywords or a wildcard. In no keywords are specified the dafault I<$File::MetaInfo::UserLabel> is queried. If '*' is used then any keyword is searched for the specified I<VALUE>.

=item * 

'VALUE' is a required label value to search in the L<File::MetaInfo::DB>.

=back

=cut


sub new{
	my $this=shift;
        my $class=ref($this) || $this;
        my %self;
	my $query=shift;
        my %options=@_;

	$self{debug}=0;
	$self{wath}='DISTINCT(FILE.ROWID)';
	@self{keys %options} = values %options;

	if (!defined($query)){
		$err=qq{Usage: File::MetaInfo::Query::Simple( \$QUERY, \%option_hashref )};
		warn $err if ($self{debug});
		return undef;
	};

	
	if (!defined($self{MetaInfoDB})){
    		warn dmsg "creating a new db connection" if $self{debug};
		$self{MetaInfoDB}=new File::MetaInfo::DB( debug => $self{debug});
		$self{MetaInfoDB_is_mine}=1;
		return undef unless $self{MetaInfoDB};
    	}

	my $self = bless \%self, $class;

	$self{clause}=$self->_parse($query);
	
	return $self;
};

sub _parse{
	my $self=shift;
	my $query=shift;
	
	my @parsed=split(':',$query);
	my $clause;
	warn dmsg "argument @parsed [" . @parsed . "]" if $debug;
	if (@parsed eq 1){ 
		$clause=qq{KEYWORDS.KEYWORD='$File::MetaInfo::UserLabel' AND KEYWORDS.VALUE LIKE '%$parsed[0]%'};
		$self->{keyword}=$File::MetaInfo::UserLabel;
		$self->{value}=$parsed[0];
	}
	if (@parsed gt 1) { 
		if ($parsed[0] =~ /\*/){
			$clause=qq{KEYWORDS.VALUE LIKE '%$parsed[1]%'};
			$self->{keyword}=".*";
			$self->{value}=$parsed[1];
		} else {
			$clause=qq{KEYWORDS.KEYWORD LIKE '%$parsed[0]%' AND KEYWORDS.VALUE LIKE '%$parsed[1]%'};
			$self->{keyword}=$parsed[0];
			$self->{value}=$parsed[1];
		}
	};
	warn dmsg "clause is \'$clause\'" if $debug;
	return $clause;
};

1;
