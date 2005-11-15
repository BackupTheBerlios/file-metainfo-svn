#!/usr/bin/perl

use strict;
package File::MetaInfo::Query;

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
use Data::Dumper;
use File::MetaInfo::DB;
use File::MetaInfo;
use File::MetaInfo::Utils qw( start_timer stop_timer );

sub dmsg{ return "*** DEBUG [$NAME]: @_ " }

sub run{
	my $self=shift;

	my $timer=File::MetaInfo::Utils::start_timer();
	my $aref=$self->{MetaInfoDB}->search_custom($self->{clause});
	warn dmsg "Query run in " . File::MetaInfo::Utils::stop_timer($timer) . "seconds" if $self->{measure};
	$timer=File::MetaInfo::Utils::start_timer();

	$self->{ids}=$aref;

	return undef unless $aref;

	my @ret;
	foreach my $id (@$aref){
		my $fi=new File::MetaInfo(
			@$id[0],
			fileInfoDB=>$self->{MetaInfoDB}
		);
		return undef unless $fi;
		$self->{results}->{$fi->{id}}=$fi;
		push @ret,$fi->{id};
	}
	#return undef unless ($ret ne '0E0');
	warn dmsg "Result generated in " . File::MetaInfo::Utils::stop_timer($timer) if $self->{measure};
	return @ret;
};

sub create_view{
	my $self=shift;
	my $sql=shift;
	return undef unless $sql;
	my $name="FileInfoSearchResult$$" . $self->{viewids}++ ;
	push @{$self->{views}},$name;
	$self->{lastqueryresult}=$self->{fileInfoDB}->create_view($name,$sql);
	return ($self->{lastqueryresult},$name) ;
}

sub drop_view{
	my $self=shift;
	my $name=shift;
	$self->{lastqueryresult}=$self->{fileInfoDB}->drop_view($name);
	return $self->{lastqueryresult} ;
}

sub dump_view{
	my $self=shift;
	my $view=$self->{views}->[0];
	my $sqlDumpView=qq{SELECT * FROM $view};
	warn dmsg "dump_view: sqlDumpView=\"$sqlDumpView\"" if $self->{debug};
	my $aref=$self->{fileInfoDB}->exec_sql($sqlDumpView);
	return $aref;
}

sub close{
	my $self=shift;
	foreach my $v (@{$self->{views}}){
		$self->drop_view($v);
	};
	if (defined($self->{fileInfoDB_is_mine})){
		$self->{fileInfoDB}->close();
	}
}

1;
