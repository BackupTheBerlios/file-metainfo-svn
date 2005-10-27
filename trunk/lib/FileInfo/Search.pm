#!/usr/bin/perl

use strict;
package FileInfo::Search;


use Carp;
use Data::Dumper;
use FileInfo::DB;

our $keyword='KEYWORDS.KEYWORD';
our $value='KEYWORDS.VALUE';
our $filename='FILE.FILENAME';
our $filepath='FILE.FILEPATH';
our @queryColumns=( $keyword, $value, $filename, $filepath );

# this create a new serarch
# parameters are 'args' and 'options'
# args is an array reference that describes the query
# The query is expressed ad:
# 	query := <element> | <elementlist>
# 	elementlist := <element>+
# 	element := <value> | <keywordvalue> | <notvalue> | <likevalue>
# 	value := <simplevalue>
# 	keywordvalue := <keyword>=<simplevalue> 
# 	notvalue := -<value>
# 	likevalue := ~<value>
# 	simplevalue: a string
# 	keyword: a string
# 
sub new{
	my $this=shift;
        my $class=ref($this) || $this;
        my %self;
        my $args=shift;
        my %options=@_;

        $self{debug}=0;

        @self{keys %options} = values %options;

	if (!defined($self{fileInfoDB})){
    		warn "DEBUG: FileInfo::Search::new creating a new db connection" if $self{debug};
		$self{fileInfoDB}=new FileInfo::DB( debug => $self{debug});
		$self{fileInfoDB_is_mine}=1;
    	}

	$self{elements}=$args;
	$self{clauses}=parse_args($args);
	return undef unless $self{clauses};
	$self{sql}=gen_sql('*',$self{clauses},$self{debug});
	return undef unless $self{sql};
	$self{views};
	$self{viewids}=0;

	#warn "DEBUG: args=@$args" if $self{debug};
		
	my $self = bless \%self, $class;
	
	my ($ret,$name)=$self->create_view($self->{sql});
	return undef unless $ret;
	#return undef unless ($ret ne '0E0');

	warn "DEBUG: self=" . Dumper($self) . "ret=$ret name=$name\n" if $self{debug};
	return $self;
}

sub parse_args($){
	my $args=shift;
	my @parsed;
	my $i=0;

	foreach (@{$args}){
		# notvalue := -<value>
		if ($args->[$i] =~ /^-(.*)$/){
			my $v=qq{NOT LIKE '%%$1%%'};
			foreach my $c (@queryColumns){
				$parsed[$i]='(' . join(' OR ',$parsed[$i],"$c $v") . ')';
			}

		}
		#likevalue := ~<value>
		elsif ($args->[$i] =~ /^~(.*)$/){
			my $v=qq{IS LIKE '%$1%'};
			foreach my $c (@queryColumns){
				$parsed[$i]='(' . join(' OR ',$parsed[$i],"$c $v") . ')';
			}
		}
		#keywordvalue := <keyword>=<simplevalue> 
		elsif ($args->[$i] =~ /^(.*)=(.*)$/){
			my $k=$1;
			my $v=$2;
			$parsed[$i]=qq{($keyword='$k' AND $value='$v')};
		}
		#value := <simplevalue>
		else{
			my $v="='" . $args->[$i] . "'";
			my @Q;
			foreach my $c (@queryColumns){
				push @Q,"$c $v";
			}
			$parsed[$i]='(' . join(' OR ',@Q) . ')';
		}
		$i++;
	}
	return \@parsed;

}

# The SQL query is created using these rules:
# 	elementlist => <element> AND <elementlist>
# 	value => = '<simplevalue>'
# 	likevalue => IS LIKE "%%<simplevalue>%%"
# 	notvalue => IS NOT LIKE "%%<simplevalue>%%
# 	
sub gen_sql{
	my $what=shift;
	my $clauses=shift;
	my $debug=shift;

	my $prefix="SELECT $what FROM FILE,KEYWORDS WHERE (FILE.ROWID=KEYWORDS.FILE_ID AND ";

	my $sql = $prefix . join(' AND ',@{$clauses}) . ')';

	#warn "DEBUG: gen_sql query=$sql" if $debug;

	return $sql;
}

sub get_filesid{
	my $self=shift;

	my $sqlSearch=gen_sql('DISTINCT FILE.ROWID',$self->{clauses},$self->{debug});
	return undef unless $sqlSearch;
	$self->{result}=$self->{fileInfoDB}->exec_sql($sqlSearch);
	return $self->{result};
}

sub create_view{
	my $self=shift;
	my $sql=shift;
	return undef unless $sql;
	my $name="FileInfoSearchView$$" . $self->{viewids}++ ;
	push @{$self->{views}},$name;
	$self->{result}=$self->{fileInfoDB}->create_view($name,$sql);
	return ($self->{result},$name) ;
}

sub drop_view{
	my $self=shift;
	my $name=shift;
	$self->{result}=$self->{fileInfoDB}->drop_view($name);
	return $self->{result} ;
}

sub dump{
	my $self=shift;
	my $view=$self->{views}->[0];
	my $sqlDumpView=qq{SELECT * FROM $view};
	warn "DEBUG: FileInfo::Search::dump sqlDumpView=\"$sqlDumpView\"" if $self->{debug};
	my $aref=$self->{fileInfoDB}->exec_sql($sqlDumpView);
	return $aref;

}

sub close{
	my $self=shift;

	if (defined($self->{fileInfoDB_is_mine})){
		$self->{fileInfoDB}->close();
	}
}

