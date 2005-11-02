#!/usr/bin/perl

use strict;
package FileInfo::ServiceClient;

use Carp;

use Data::Dumper;

our $StartQueryTag='Q{';
our $EndQueryTag='}';
our $sep='+';

my $requestpipe=$ENV{HOME} . "/.FileInfo/FileInfoSearchServiceRequest";
my $responsepipe=$ENV{HOME} . "/.FileInfo/FileInfoSearchServicePipe";

my $myname=__PACKAGE__;

sub new{
	my $this=shift;
	my $class=ref($this) || $this;
	my %self;
	my %args=@_;

	$self{debug}=0;
	$self{requestpipe}=$requestpipe;
	$self{responsepipe}=$responsepipe;
	@self{keys %args} = values %args;
	$self{clientid}="$myname-$$";
	warn "*** DEBUG [$myname]: waiting for server to connect to response pipe ***" if $self{debug};
	open($self{_responsepipefh},'<', $self{responsepipe}) || return undef;
	warn "*** DEBUG [$myname]: response pipe opened ***" if $self{debug};
	warn "*** DEBUG [$myname]: waiting for server to connect to request pipe ". $self{requestpipe} . " ***" if $self{debug};
	my $fh;
	open($fh,'>>', $self{requestpipe}) || return undef;
	my $old_fh = select($fh);
	$| = 1;
	select($old_fh);
	$self{_requestpipefh}=$fh;
	warn "*** DEBUG [$myname]: request pipe opened ***" if $self{debug};
	my $self = bless \%self, $class;
        carp Dumper($self) if ($self{debug});
        return $self;
}

#
# Request must have this form:
# 	servicequery := <clientid><sep><startquerytag><sep><keyword_list><sep><clause><sep><values><sep><endquerytag>
#
# 	startquerytag 	:= 'Q{'
# 	sep 		:= '+'
# 	clientid 	:= NUMBER*
# 	keyword_list  	:= <keyword>(,<keyword>)*
# 	keyword 	:= STRING
# 	clause 		:= STRING
# 	values 		:= <value>(,<value>)*
# 	value 		:= STRING
# 	endquerytag 	:= '}'
#
#
sub send{
	my $self=shift;
	my $keywords=shift || undef;
	my $clause=shift || undef;
	my $values=shift || undef;

	if(defined($keyword)){
		$self->{keyword}=$keywords;
	}
	return -1 unless defined($self->{keyword});

	if (defined($clause)){
		$self->{clause}=$clause;
	}
	return -1 unless defined($self->{clause});

	if (defined($values)){
		$self->{values}=$values;
	}
	return -1 unless defined($self->{values});

	warn "*** DEBUG [$myname]: sending keyword '" . $self->{keyword} . "' ***" if $self->{debug};
	my $self->{lastrequest}=$self->{clientid} . $sep . 
			$StartQueryTag . $sep . 
			join(',',@{$self->{keyword}}) . $sep .
			$self->{clause} . $sep .
			join(','@{$self->{values}}) . $sep .
			$EndQueryTag;

	print {$self->{_requestpipefh}} $self->{lastrequest} . "\n" || return -1;
	return 0;
}

sub parse_result{
	my $self=shift;
	my $buffer=shift;
	my $fiSearchResult;
	{
		local $Data::Dumper::Purity = 1;
             	eval $buffer;
        }
	return $fiSearchResult
}

sub close{
	my $self=shift;
	close($self->{_requestpipefh});
}

