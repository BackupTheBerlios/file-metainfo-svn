package FileInfo::Service::Request;
use strict;
use warnings;
use Carp;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
}

our $Start='<R%';
our $End='%R>';
our $sep='+';

my $myname=__PACKAGE__;


#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

FileInfo::Service::Request - Put abstract here 

=head1 SYNOPSIS

 use FileInfo::Service::Request;
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

 $rv = FileInfo::Service::Request->new();

Description of new...

=cut


sub new {
    my $this=shift;
    my $class=ref($this) || $this;
    my %self;
    my %options=@_;

    $self{debug}=0;
    $self{requestid}=$$ . time;

    @self{keys %options} = values %options;

    my $self = bless \%self, $class;    
    return $self;
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
