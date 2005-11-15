#!/usr/bin/perl

use strict;
package FileInfo::Query;

our $NAME=__PACKAGE__;
our $VERSION="0.2";


use Carp;
use Data::Dumper;
use FileInfo::DB;
use FileInfo;
use Switch;
use FileInfo::Utils qw( start_timer stop_timer );

our $col_keyword='KEYWORDS.KEYWORD';
our $col_value='KEYWORDS.VALUE';
our $col_filename='FILE.FILENAME';
our $col_filepath='FILE.FILEPATH';
our @queryColumns=( $col_keyword, $col_value, $col_filename, $col_filepath );
my $default_keyword=$FileInfo::UserLabel;
our $equal='equal';
our $contain='contain';
our $start_with='start_with';
our $end_with='end_with';

# this create a new serarch
# parameters are 'args' and 'options'
# args is an array reference that describes the query
# Query object is formed like this:
# 	keywords  := <keyword>*
# 	condition := equal | contain | start_with | end_with
# 	values     := <value>*
#

sub dmsg{ return "*** DEBUG [$NAME]: @_ " }


sub new{
	my $this=shift;
        my $class=ref($this) || $this;
        my %self;
        my %arguments=@_;

	my $timer=FileInfo::Utils::start_timer();

        $self{debug}=0;
	# Default value
	$self{values}=undef;

        @self{keys %arguments} = values %arguments;
	$self{keywords}=[ 
		$default_keyword
	] unless defined(${$self{keywords}}[0]);
	$self{condition}=$equal unless defined($self{condition});
	
	warn dmsg Dumper(\%self) if $self{debug};

	return undef unless $self{values};

	if (!defined($self{fileInfoDB})){
    		warn dmsg "creating a new db connection" if $self{debug};
		$self{fileInfoDB}=new FileInfo::DB( debug => $self{debug});
		$self{fileInfoDB_is_mine}=1;
		return undef unless $self{fileInfoDB};
    	}

	$self{query}=_parse('DISTINCT(FILE.ROWID)',$self{condition},$self{keywords},$self{values},$self{debug});
	return undef unless $self{query};

	$self{views};
	$self{viewids}=0;

	warn dmsg "Object generated in " . FileInfo::Utils::stop_timer($timer) if $self{measure};

	my $self = bless \%self, $class;
	
	return $self;
}

sub run{
	my $self=shift;

	#my ($ret,$name)=$self->create_view($self->{query});
	#return undef unless $ret;
	#warn "DEBUG: view=" . Dumper($self->{views}) . "ret=$ret name=$name\n" if $self->{debug};
	my $timer=FileInfo::Utils::start_timer();
	my @ret;
	my $aref=$self->{fileInfoDB}->exec_sql($self->{query});
	return undef unless $aref;
	foreach my $id (@$aref){
		my $fi=new FileInfo(
			@$id[0],
			fileInfoDB=>$self->{fileInfoDB}
		);
		return undef unless $fi;
		$self->{results}->{$fi->{id}}=$fi;
		push @ret,$fi->{id};
	}
	#return undef unless ($ret ne '0E0');
	warn dmsg "Result generated in " . FileInfo::Utils::stop_timer($timer) if $self->{measure};
	return @ret;
}


# The SQL query is generated as:
# 	query := ( clause ) | [( clause ) AND ( clause )]*
# 	clause := keyword condition value
#
sub _compose($){
	my $what=shift;
	my $condition=shift;
	my $keywords=shift;
	my $values=shift;
	my $debug=shift || undef;
	my $prefix=shift || "SELECT $what FROM FILE,KEYWORDS WHERE (FILE.ROWID=KEYWORDS.FILE_ID AND ";
	my $query;
	my $i=0;
	my @clauses;
	warn dmsg "parse - Enter" if $debug;
	
	foreach my $keyw (@{$keywords}){
		my $keyclause="KEYWORD = '$keyw'";
		foreach my $val (@{$values}){
			my $sql;
			warn dmsg "keyword=$keyw value=$val clause=$condition" if $debug;
			if ($condition eq $equal){ $sql="( $keyclause AND VALUE='$val' )"; }
			elsif ($condition eq $start_with){ $sql="( $keyclause AND VALUE LIKE '$val%' )"; }
			elsif ($condition eq $end_with){ $sql="( $keyclause AND VALUE LIKE '%$val' )"; }
			elsif ($condition eq $contain){ $sql="( $keyclause AND VALUE LIKE '%$val%')"; }
			warn dmsg "clause=$sql" if $debug;
			push @clauses,$sql;
		}
	}

	$query = $prefix . join(' AND ',@clauses) . ')';
	warn dmsg "query=$query" if $debug;

	warn dmsg "parse - Exit" if $debug;
	return $query;
}


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

