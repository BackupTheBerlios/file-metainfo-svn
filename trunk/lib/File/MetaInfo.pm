package File::MetaInfo;

use strict;
use warnings;

use Carp;
use Cwd 'abs_path';
use Term::ReadLine;
use File::Basename;
use File::MetaInfo::Plugins;
use File::MetaInfo::DB;
use Data::Dumper;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
}

#------

our $Moved='M';
our $Changed='C';
our $UserLabel='File::MetaInfo::User.labels';
our $UserRate='File::MetaInfo::User.rate';
my $iconSize=48;
my $myname=__PACKAGE__;

sub dmsg{ return "*** DEBUG [$myname]: @_" }

sub new{
	my $this=shift;
	my $class=ref($this) || $this;
	my %self;
	my $arg=shift;
	my %options=@_;

	$self{debug}=0;
	$self{volumeid}='0';

	$self{infokeys}=[ 'id', 'filename', 'fullpath', 'title', 'summary', 'mimetype'];
	
	@self{keys %options} = values %options;
	
	if(!defined($self{volumeid})){
			$self{volumeid}='0';
	}
    
    	if (!defined($self{fileInfoDB})){
    		warn "DEBUG: File::MetaInfo::new creating a new db connection" if $self{debug};
		$self{fileInfoDB}=new File::MetaInfo::DB( debug => $self{debug});
    	}

	if ($arg =~ /^\d*$/){
		warn "DEBUG: File::MetaInfo::new arg is an id: $arg" if $self{debug};
		$self{id}=$arg;
	} 
	elsif ($arg =~ /^\//){
		warn "DEBUG: File::MetaInfo::new arg is a fullpath: $arg" if $self{debug};
		$self{fullpath}=$arg;
		$self{id}=$self{fileInfoDB}->get_file_id($self{fullpath});
	}
	else{ return undef }

	if (!defined($self{id}) && !defined($self{dontcreate})){
		$self{fileInfoDB}->add_file($self{fullpath},$self{volumeid});
		$self{id}=$self{fileInfoDB}->get_file_id($self{fullpath});
		my $self = bless \%self, $class;
		$self->update_keywords();
		$self->add_keyword('volumeid',[ $self{volumeid} ]);
		#add_keyword(\%self,'filepath',[ $self{filepath}]);
		$self{fresh}=1;
	}

	my $hr=$self{fileInfoDB}->get_file_hashref($self{id});
	@self{keys %$hr} = values %$hr;
	$hr=$self{fileInfoDB}->get_values_hashref($self{id});
	$self{keywords} = $hr;
	$self{keywords_lastrefresh}=time;
	#warn "DEBUG: hr=" . Dumper($hr);
	#@self{keys %$hr} = values %$hr;
	$self{fullpath}=join('/',$self{filepath},$self{filename});
	$self{url}="file://" . $self{fullpath};
	$self{changed}=0;
	$self{removed}=0;
	
	warn "DEBUG: File::MetaInfo::new fullpath=$self{fullpath} fileID=$self{id}" if ($self{debug});

	my $self = bless \%self, $class;

	carp Dumper($self) if ($self{debug});
	
	return $self;
}

sub changed{
	my $self=shift;
	my @stats = stat($self->{fullpath});
	return 0 unless ($self->{volumeid} eq 0);
	#print "DEBUG: " . Dumper(\@stats) if ($self->{debug});
	if (!defined($stats[0])){
		warn "DEBUG: file has been (probably) removed" if ($self->{debug});
		$self->{changed}=-1;
		$self->{removed}=1;
		$self->{fileInfoDB}->update_status($self->{id},$Moved);
		return $self->{changed};

	}
	if ($stats[9] ne $self->{mtime}){
		warn "DEBUG: file needs update. mtime=$stats[9]" if ($self->{debug});
		$self->{changed}=($stats[9] - $self->{mtime});
		$self->{fileInfoDB}->update_status($self->{id},$Changed);
		return $self->{changed};
	}
	else{
		warn "DEBUG: file does NOT need update" if ($self->{debug});
		$self->{changed}=0;
		return $self->{changed};
	}
}

sub close{
	my $self=shift;
	if (defined($self->{gnome2vfs})){
		warn dmsg "Shutting down Gnome2::VFS" if ($self->{debug});
		Gnome2::VFS->shutdown();
		$self->{gnome2vfs}=undef;
	}
	warn dmsg "Closing DB" if ($self->{debug});
	$self->{fileInfoDB}->close();
	undef $self;
};

sub add_keyword($$$){
	my $self=shift;
	my $keyword=shift;
	my $value=shift;
	push @{$self->{keywords}->{$keyword}},$value;
	warn Dumper($self->{keywords}) if ($self->{debug});
	return $self->{fileInfoDB}->update_keywords($self->{id},$self->{keywords});
}

sub replace_keyword{
	my $self=shift;
	my $keyword=shift;
	my $value=shift;
	my @values;
	push @values,$value;
	warn dmsg "values=" . Dumper(\@values) if $self->{debug};
	$self->{keywords}->{$keyword}=\@values;
	warn Dumper($self->{keywords}) if ($self->{debug});
	return $self->{fileInfoDB}->update_keywords($self->{id},$self->{keywords});
}

sub extract_keywords{
	my $self=shift;
	
	my $plugins=$self->{fileInfoDB}->list_plugins();
	my %h;
	warn "DEBUG: File::MetaInfo plugins:" . Dumper($plugins) if $self->{debug};
	foreach my $k (@$plugins){
		my $class = $k->[0];
		warn "Class: $class\n" if $self->{debug};
		eval "require $class";
		my $p=$class->new($self->{fullpath},
			exclude => $self->{excludeKeywords});
		if ($p){
			my $e=$p->extract();
			if($e){
				warn join(',',(keys %$e)) . "\n" if $self->{debug};
				@h{keys %$e} = values %$e;
			}
			#warn Dumper ($e) if $self->{debug};
		}
	}
	#warn Dumper (\%h) if $self->{debug};
	return \%h;
}

sub update_keywords{
	my $self=shift;
	
	my $kv_ref=$self->extract_keywords();
	my $ret=$self->{fileInfoDB}->update_keywords($self->{id},$kv_ref); 
	return $ret;
}

sub reset_status{
	my $self=shift;

	my $ret=$self->{fileInfoDB}->reset_status($self->{id},$self->{fullpath});

	if (!defined($ret)){
		warn "DEBUG: file has been (probably) removed" if ($self->{debug});
		$self->{changed}=-1;
		$self->{removed}=1;
		$self->{fileInfoDB}->update_status($self->{id},$Moved);
		$ret=-1;
	}
	return $ret;
}

sub update{
	my $self=shift;
	
	my $ret=$self->update_keywords();	
	if ($ret){
		return $self->reset_status();
	}
}

sub describe_plugins{
	my $self=shift;
	
	my $plugins=$self->{fileInfoDB}->list_plugins();
	#warn Dumper($plugins) if $self->{debug};
	foreach my $k (@$plugins){
		my $class = $k->[0];
		warn "Class: $class\n" if $self->{debug};
		eval "require $class";
		my $p=$class->new($self->{fullpath});
		$p->describe();
	}
}

sub get_keywords{
	my $self=shift;
	return $self->{fileInfoDB}->get_keywords($self->{id});
}

sub get_values{
	my $self=shift;
	warn "WARNING: get_values deprecated method use File::MetaInfo->{keywords}";
	$self or return undef;
	return $self->{fileInfoDB}->get_values($self->{id});
}

sub get_values_hashref{
	my $self=shift;
	warn "WARNING: get_values_hashref deprecated use File::MetaInfo->{keywords}";
	$self or return undef;
	my $arrayref=$self->{fileInfoDB}->get_values($self->{id});
	my %h;
	foreach (@$arrayref){
		push @{$h{$_->[0]}},$_->[1];
	}
	#warn Dumper(\%h) if ($self->{debug});
	return \%h;
}

sub refresh_keywords{
	my $self=shift;
	$self->{keywords}=$self->{fileInfoDB}->get_values_hashref($self->{id});
	$self->{keywords_lastrefresh}=time;
}

sub refresh_vfsinfo{
	my $self=shift;
	my $ret1=$self->get_gnome2_vfs_info;
	my $ret2=$self->get_gnome2_mime_info;
	if (defined($ret1) && defined($ret2)){
		$self->{vfsinfo_lastrefresh}=time;
		return 0;
	}
	return undef;
}

sub get_gnome2_vfs_info{
	my $self=shift;
	use Gnome2::VFS;
	my $prefix="File::MetaInfo::Gnome2VFS";
	my $ret;
	my $gfi;

	if ($self->{volumeid} ne 0){
		warn "Warning: File is not local. Exiting" if $self->{debug};
		return undef;
	}

	if (!-f $self->{fullpath}){
		warn "Warning: file does not exists. Exiting" if $self->{debug};
		return undef;
	}

	if (!defined($self->{gnome2vfs})){
		$self->{gnome2vfs}=Gnome2::VFS->init();
		warn "Warning: $@\n" if $self->{debug};
		$self->{gnome2vfs} or return undef;
	}
	my $gfh=Gnome2::VFS->open($self->{fullpath},"read");
	$gfh or return undef;
	($ret,$gfi)=$gfh->get_file_info("default");
	warn "DEBUG: {gnome2-vfs-info} - " . Dumper($self->{gnome2_vfs_info}) if ($self->{debug});

	for my $k (keys (%{$gfi})){
		my $newk=$prefix . "." . $k;
		$self->{vfsinfo}->{$newk}=$gfi->{$k};
	}
	$gfh->close();
	return $gfi
}

sub get_gnome2_mime_info{
	my $self=shift;

	use Gnome2::VFS;
	use Gtk2 -init;
	my $iconInfo;
	my $iconFile;
	my $prefix="File::MetaInfo::Gnome2VFS";
	my $gmi;

	my $mime=Gnome2::VFS->get_mime_type($self->{fullpath});
	my $mime_type = new Gnome2::VFS::Mime::Type($mime);
	my $applist = $mime_type->get_all_applications();
	my $application = $mime_type->get_default_application();
	my $mimeactiontype = $mime_type->get_default_action_type();
	my $iconName = $mime_type->get_icon();
	if (!$iconName){
		$iconName = "gnome-mime-" . $mime;
		$iconName =~ s#/#-#;
	}
	my $iconTheme= Gtk2::IconTheme->get_default;
	if ($iconTheme && $iconTheme->has_icon($iconName)){
		$iconInfo = $iconTheme->lookup_icon($iconName,$iconSize,'use-builtin');
		$iconFile = $iconInfo->get_filename if($iconInfo);
	}
	else{
		$mime =~ m#^(.*)/.*$#;
		$iconName= "gnome-mime-" . $1;
		$iconInfo = $iconTheme->lookup_icon($iconName,$iconSize,'use-builtin');
		$iconFile = $iconInfo->get_filename if($iconInfo);
	}
	$self->{vfsinfo}->{$prefix . ".default_action"}=$mimeactiontype;
	$self->{vfsinfo}->{$prefix . ".default_application"}=$application;
	$self->{vfsinfo}->{$prefix . ".applications_list"}=$applist;
	$self->{vfsinfo}->{$prefix . ".icon_name"}=$iconName;
	$self->{vfsinfo}->{$prefix . ".icon_file"}=$iconFile;
	$self->{vfsinfo}->{$prefix . ".icon_info"}=$iconInfo;
	if ($self->{debug}){
		warn "gnome2-mime-info: " . Dumper($self->{gnome2_mime_info}) ."\n";
	}
	return 0;
}

sub print_plugins{
	my $self=shift;
	print Dumper($self->{fileInfoDB}->list_plugins());
}

sub print_keywords{
	my $self=shift;
	my $sep=shift || "\n";
	my $arrayref=$self->get_keywords($self->{id});
	foreach (@$arrayref){
		print "$_->[0]$sep";
	}
}

sub dump_keywords{
	my $self=shift;
	my $arrayref=$self->get_keywords($self->{id});
	print Dumper($arrayref);
}

sub print_values{
	my $self=shift;
	my $sep1=shift || "=";
	my $sep2=shift || "\n";
	my $sep3=shift || ",";
	my $OUT=shift || \*STDOUT;
	my $h=$self->get_values_hashref();
	foreach my $k (sort(keys %{$h})){
		print $OUT "$k$sep1" . join ($sep3, @{$h->{$k}}) . "$sep2";
	}
}

sub print_info{
	my $self=shift;
	my $sep1=shift || "=";
	my $OUT=shift || \*STDOUT;
	my $sep2=shift || ',';
	foreach my $k (@{$self->{infokeys}}){
		if (defined($self->{$k})){
			if (ref($self->{$k}) eq "ARRAY" ){
				print $OUT "$k$sep1";
				print $OUT join($sep2,@{$self->{$k}});
				print "\n";
			}
			else{
				print $OUT "$k$sep1$self->{$k}\n";
			}
		}
	}
	my $s=$self->changed();
                if ( $s ne 0){
                        print $OUT "WARNING: File has been modified. ";
                        print $OUT "Info are outdated by $s seconds." if ($s gt 0);
                        print $OUT "File has been (re)moved." if ($s lt 0);
                        print $OUT "\n";
                }
}

sub print_gnome2_info{
	my $self=shift;

	$self->get_gnome2_vfs_info();
	return unless $self->{gnome2_vfs_info};
	$self->get_gnome2_mime_info();
	return unless $self->{gnome2_mime_info};
	print Dumper($self->{gnome2_vfs_info});
	print Dumper($self->{gnome2_mime_info});
}

sub print_summary{
	my $self=shift;
	my $sep1=shift || "=";
	my $OUT=shift || \*STDOUT;
	print $OUT "$self->{filename}\n";

}

#sub auto_labels{
	#my $self=shift;
	#my $tokens=shift || '/';
	#my $fdir=lc dirname($self->{fullpath});
	#my @auto_labels=split(/$tokens/,$fdir);
	#warn "DEBUG: @auto_labels" if ($self->{debug});
	#return $self->{fileInfoDB}->add_labels($self->{id},\@auto_labels,$File::MetaInfo::DB::AutoLabel);
#}

sub shell{
	my $fn=shift;
	#$fn=abs_path($fn);
	#croak "FATAL: you must specify a file name" unless (-f $fn);
	my $fi=new File::MetaInfo($fn, debug => 1 )|| die "$!";
	my $term = new Term::ReadLine 'File::MetaInfo Shell';
	my $prompt0 = "File::MetaInfo";
	my $OUT = $term->OUT || \*STDOUT;
	my $prompt = $prompt0 . "[]> ";
	while ( defined ($_ = $term->readline($prompt)) ) {
		my $ret="";
		#print $OUT "#$_\n" unless $@;
		if ($_ =~ /^quit$/ || $_ =~ /^q$/){
			return
		}
		if ($_ !~ /^$/){
			eval {
			  $ret=$fi->$_();
			}; warn $@ if $@;
			$term->addhistory($_) if /\S/;
		}
		$prompt=$prompt0 . "[$ret]> ";
	}

}

sub get_DB{
	my $self=shift;
	return $self->{fileInfoDB};
};

sub last_err{
	my $self=shift;
	return $self->{fileInfoDB}->last_err();
}

sub test($){

}

1
