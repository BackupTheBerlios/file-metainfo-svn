#!/usr/bin/perl
use strict;

package FileInfo::Plugins::Nautilus;
use base qw(FileInfo::Plugins);

#use AutoLoader;

use XML::Simple;
use File::Basename;
use Cwd qq{abs_path};
#use Data::Dumper;

my $packname = __PACKAGE__;
my $keyword=$packname . ".emblem";
	
sub new{
	my $this=shift;
	my $class=ref($this) || $this;
	my %self;
	my $filename=shift;
	my %options=@_;
	
	$self{debug}=0;
	$self{metafilesdir}=$ENV{HOME} . "/.nautilus/metafiles";
	
	$self{filename}=basename($filename);
	$self{filename}=~ s/([^A-Za-z0-9\.-])/sprintf("%%%02X", ord($1))/seg;
	my $dirname=dirname($filename);
	my $dirurl=lc ("//" . abs_path($dirname));

	$dirurl =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	$self{metafilename}="file:" . $dirurl . ".xml";
	
	if (! (-f $self{metafilename})){
		return undef;
	}
	@self{keys %options} = values %options;
	
	$self{metafile}=$self{metafilesdir} . "/" . $self{metafilename};
	
    my $self = bless \%self, $class;
    return $self;
};

sub extract{
	my $self=shift;
	my $xs1 = XML::Simple->new();
	my $doc = $xs1->XMLin($self->{metafile})|| die "$!\n";
	my $fn= $self->{filename};
    my $fileinfo=$doc->{file}->{$fn};
    my %hash;
    
    foreach my $k (keys (%{$fileinfo->{keyword}})){
			if(ref($fileinfo->{keyword}->{$k}) eq "HASH"){
					push (@{$hash{$keyword}}, $k); 
			}
	    	else{
	    		push (@{$hash{$keyword}}, $fileinfo->{keyword}->{$k});
	    	}
    }
    
    return \%hash;
};

#sub test{
#	use Data::Dumper;
#	my $file=shift;
#	my $p=new FileInfo::Plugins::Nautilus($file, debug => 1);
#	
#	print "@FileInfo::Plugins::Nautilus::ISA\n";
#	$p->describe();
#   print Dumper($p->extract());
#}

1
__END__
