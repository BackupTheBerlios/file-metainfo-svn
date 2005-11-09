package FileInfo::Service;
use strict;
use warnings;
use Carp;
use FileInfo;
use FileInfo::DB;
use FileInfo::Query;
use Data::Dumper;
use Getopt::Long;
use Carp;
use Fcntl;
use POSIX ":sys_wait_h";
use POSIX qw(strftime);


BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
}

our $StartQueryTag='Q{';
our $EndQueryTag='}';
our $sep=qw(+);
our $StartResponseTag='<R%';
our $EndResponseTag="%R>\n";

my $myname=__PACKAGE__;

my $requestpipe=$ENV{HOME} . "/.FileInfo/FileInfoSearchServicePipe";
my $responsepipe=$ENV{HOME} . "/.FileInfo/FileInfoSearchServiceRequest";


#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

FileInfo::Service - Put abstract here 

=head1 SYNOPSIS

 use FileInfo::Service;
 blah blah blah

=head1 DESCRIPTION

Description...

=head1 USAGE

Usage...

=cut

#--------------------------------------------------------------------------#
# new()
#--------------------------------------------------------------------------#

=head2 new

 $rv = FileInfo::Service->new();

Description of new...

=cut


sub new {
    my $this=shift;
    my $class=ref($this) || $this;
    my %self;
    my %options=@_;
   
    $self{debug}=0; 
    $self{requestpipe}=$requestpipe;
    $self{responsepipe}=$responsepipe;
    $self{serverid}=$$;

    @self{keys %options} = values %options;

    if (!defined($self{fileInfoDB})){
    		warn dmsg "creating a new db connection" if $self{debug};
		$self{fileInfoDB}=new FileInfo::DB( debug => $self{debug});
    }

    unless (-p $self{requestpipe} && -p $self{responsepipe}) {
	unlink $self{responsepipe};
	require POSIX;
	POSIX::mkfifo($self{requestpipe}, 0666) or die "can't mknod ". $self{requestpipe} . ": $!";
       	warn dmsg "created " . $self{requestpipe} . " as a named pipe\n" if $debug;
	unlink $self{responsepipe};
	POSIX::mkfifo($self{responsepipe}, 0666) or die "can't mknod " . $self{responsepipe} . ": $!";
       	warn dmsg "created " . $self{responsepipe} . " as a named pipe\n" if $debug;

    }

    open ($fh,'>',$self{responsepipe})|| die "Can't write to " . $self{responsepipe} . ": $!";
    my $old_fh = select($fh);
    $| = 1;
    select($old_fh);
    $self{_responsepipefh}=$fh;
	
    my $self = bless ({ }, %self);
    return $self;
}

sub close{
    my $self=shift;

    close($self->{_responsepipefh});
    close($self->{_requestpipefh});
	
}

sub next_request{
    my $self=shift;
    my $fh;

    if (!defined($self->{_requestpipefh})){
	    open ($fh,'<',$self->{requestpipe})|| die "Can't read from " . $self->{requestpipe} . ": $!";
    }
    $self->{_requestpipefh}=$fh;
    return <{$self->{_requestpipefh}}>;
}

sub dmsg{ return "*** DEBUG [$myname]: @_ " };

sub logmsg { 
  if (@_){
    warn "INFO [$myname]: @_ at ", (strftime "%Y%m%d%H%M%S", localtime), "]\n" ;
  }
}

1; #this line is important and will help the module return a true value
__END__

=head1 BUGS

Please report bugs using the CPAN Request Tracker at 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=

=head1 AUTHOR

 





=head1 COPYRIGHT

Copyright (c) 2005 by 

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut




