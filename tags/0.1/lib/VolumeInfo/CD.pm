#!/usr/bin/perl
#

package VolumeInfo::CD;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $debug);

use Fcntl;
use IO::Socket;
use Config;
use Data::Dumper qw(Dumper);
use Cwd 'abs_path';

#$debug=1;

# setup for linux, solaris x86, solaris spark
# you freebsd guys give me input 

print STDERR "cddb: checking for os ... " if $debug;

my $os=`uname -s`;
my $machine=`uname -m`;
chomp $os;
chomp $machine;

print STDERR "$os ($machine) " if $debug;

# cdrom IOCTL magic (from c headers)
# linux x86 is default

# /usr/include/linux/cdrom.h
my $CDROMREADTOCHDR=0x5305;
my $CDROMREADTOCENTRY=0x5306;
my $CDROM_MSF=0x02;
my $CD_MSF_OFFSET=150;
my $CD_FRAMES=75;

# default config

my $CDDB_HOST = "freedb.freedb.org";
my $CDDB_PORT = 888;
my $CDDB_MODE = "cddb";
my $CD_DEVICE = "/dev/cdrom";

my $HELLO_ID  = "root nowhere.com fastrip 0.77";
my $PROTO_VERSION = 5;

# endian check

my $BIG_ENDIAN = unpack("h*", pack("s", 1)) =~ /01/;

if($BIG_ENDIAN) { 
  print STDERR "[big endian] " if $debug;
} else {
  print STDERR "[little endian] " if $debug;
}

# 64bit pointer check

my $BITS_64 = $Config{ptrsize} == 8 ? 1 : 0;

if($BITS_64) {
  print STDERR "[64 bit]\n" if $debug;
} else {
  print STDERR "[32 bit]\n" if $debug;
}

if($os eq "SunOS") {
  # /usr/include/sys/cdio.h

  $CDROMREADTOCHDR=0x49b;	# 1179
  $CDROMREADTOCENTRY=0x49c;	# 1180

  if(-e "/vol/dev/aliases/cdrom0") {
    $CD_DEVICE="/vol/dev/aliases/cdrom0";
  } else {
    if($machine =~ /^sun/) {  
      # on sparc and old suns
      $CD_DEVICE="/dev/rdsk/c0t6d0s0";
    } else {
      # on intel 
      $CD_DEVICE="/dev/rdsk/c1t0d0p0";
    }
  }
} elsif($os =~ /BSD/i) {  # works for netbsd, infos for other bsds welcome
  # /usr/include/sys/cdio.h

  $CDROMREADTOCHDR=0x40046304;
  $CDROMREADTOCENTRY=0xc0086305;

  if($BITS_64) {
    $CDROMREADTOCENTRY=0xc0106305;
  }

  $CD_DEVICE="/dev/cd0a";

  if($os eq "OpenBSD") {
    $CD_DEVICE="/dev/cd0c";
  }
}

sub read_toc {
  my $device=shift;
  my $tochdr="";

  sysopen (CD,$device, O_RDONLY | O_NONBLOCK) or die "cannot open cdrom [$!] [$device]";
  ioctl(CD, $CDROMREADTOCHDR, $tochdr) or die "cannot read toc [$!] [$device]";
  my ($start,$end);
  if($os =~ /BSD/) {
    ($start,$end)=unpack "CC",(substr $tochdr,2,2);
  } else {
    ($start,$end)=unpack "CC",$tochdr;
  }
  print STDERR "start track: $start, end track: $end\n" if $debug;

  my @tracks=();

  for (my $i=$start; $i<=$end;$i++) {
    push @tracks,$i;
  }
  push @tracks,0xAA;

  my @r=();
  my $tocentry;
  my $toc="";
  my $size=0;
  for(@tracks) {
    $toc.="        ";
    $size+=8;
  }
 
  if($os =~ /BSD/) { 
    my $size_hi=int($size / 256);
    my $size_lo=$size & 255;      

    if($BIG_ENDIAN) {
      if($BITS_64) {
        # better but just perl >= 5.8.0
        # $tocentry=pack "CCCCx![P]P", $CDROM_MSF,0,$size_hi,$size_lo,$toc; 
        $tocentry=pack "CCCCxxxxP", $CDROM_MSF,0,$size_hi,$size_lo,$toc; 
      } else {
        $tocentry=pack "CCCCP8l", $CDROM_MSF,0,$size_hi,$size_lo,$toc; 
      }
    } else {
      if($BITS_64) {
        $tocentry=pack "CCCCxxxxP", $CDROM_MSF,0,$size_lo,$size_hi,$toc; 
      } else {
        $tocentry=pack "CCCCP8l", $CDROM_MSF,0,$size_lo,$size_hi,$toc; 
      }
    }
    ioctl(CD, $CDROMREADTOCENTRY, $tocentry) or die "cannot read track info [$!] [$device]";
  }

  my $count=0;
  foreach my $i (@tracks) {
    my ($min,$sec,$frame);
    unless($os =~ /BSD/) {
      $tocentry=pack "CCC", $i,0,$CDROM_MSF;
      ioctl(CD, $CDROMREADTOCENTRY, $tocentry) or die "cannot read track $i info [$!] [$device]";
      ($min,$sec,$frame)=unpack "CCCC", substr($tocentry,4,4);
    } else {
      ($min,$sec,$frame)=unpack "CCC", substr($toc,$count+5,3);
    } 
    $count+=8;

    my %cdtoc=();
 
    $cdtoc{min}=$min;
    $cdtoc{sec}=$sec;
    $cdtoc{frame}=$frame;
    $cdtoc{frames}=int($frame+$sec*$CD_FRAMES+$min*60*$CD_FRAMES);

    my $data = unpack("C",substr($tocentry,1,1)); 
    $cdtoc{data} = 0;
    if($data & 0x40) {
      $cdtoc{data} = 1;
    } 

    push @r,\%cdtoc;
  }   
  close(CD);
 
  return @r;
}                                      

sub cddb_sum {
  my $n=shift;
  my $ret=0;

  while ($n > 0) {
    $ret += ($n % 10);
    $n = int $n / 10;
  }
  return $ret;
}                       

sub cd_discid {
  my $last=shift;
  my $toc=shift;

  my $i=0;
  my $totaltime=0;
  my $n=0;
  my $cksum;
  
  #print "\ntoc=" . Dumper($last,$toc);

  while ($i < $last) {
    $cksum += cddb_sum(($toc->[$i]->{min} * 60) + $toc->[$i]->{sec});
    $i++;
  }
  $totaltime = (($toc->[$last]->{min} * 60) + $toc->[$last]->{sec}) -
      (($toc->[0]->{min} * 60) + $toc->[0]->{sec});
  return sprintf ("%08lx", ($cksum % 0xff) << 24 | $totaltime << 8 | $last);
}                                     

sub cd_length{
  my $last=shift;
  my $toc=shift;
  my $length=0;
  my $i=0;

  return (($toc->[$last]->{min} * 60) + $toc->[$last]->{sec})
}

sub get_discids {
  my $cd=shift;
  $CD_DEVICE = $cd if (defined($cd));
  #$CD_DEVICE = abs_path($cd) if (defined($cd));

  my @toc=read_toc($CD_DEVICE);
  my $last=$#toc;

  my $id=cd_discid($last,\@toc);
  my $length=cd_length($last,\@toc);

  print "return [$id,$last,$length,@toc]\n" if $debug;
  return ($id,$last,$length,\@toc);
}

sub real_device{
	my $cd=shift;
	#return abs_path($cd) if (defined($cd));
}

sub test {
	my @t=get_discids($ARGV[0]);
	use Data::Dumper;
	print Dumper(\@t);
}

sub mount_point{
	my $cd=shift;
	#$CD_DEVICE = abs_path($cd) if (defined($cd));
  	$CD_DEVICE = $cd if (defined($cd));
	my $fsinfo=_info();
	return $fsinfo->{$CD_DEVICE}->{mount_point};
}

sub device{
	my $mount_point=shift;
	my $fsinfo=_info();
	#warn Dumper($fsinfo);
	foreach my $k (keys(%$fsinfo)){
		my $mp=$fsinfo->{$k}->{mount_point};
		if ($mp){
			warn "$k $mount_point =~ #^$mp# ?";
			return $fsinfo->{$k}->{device} if ($mount_point =~ m#^$mp#);
		}
	}
	return undef;
}

sub is_mounted{
	my $cd=shift;
	#$CD_DEVICE = abs_path($cd) if (defined($cd));
  	$CD_DEVICE = $cd if (defined($cd));
	my $fsinfo=_info();
	return $fsinfo->{$CD_DEVICE}->{mounted};
}

sub _info{
	my $fsinfo;
	my $fstab ||= '/etc/fstab';
	my $mtab ||= '/etc/mtab';
	my $xtab ||= '/etc/lib/nfs/xtab';

	# Default fstab and mtab layout
	my @keys = qw(fs_spec fs_file fs_vfstype fs_mntops fs_freq fs_passno);

	# Read the fstab
	open(FSTAB,"$fstab") || die "Could not open $fstab";
	while (<FSTAB>) {
		next if /^\s*#/;
		my @vals = split(/\s+/, $_);
		$fsinfo->{$vals[0]}->{mount_point} = $vals[1];
		$fsinfo->{$vals[0]}->{device} = $vals[0];
		$fsinfo->{$vals[0]}->{unmounted} = 1;
		$fsinfo->{$vals[0]}->{special} = 1 if grep(/^$vals[2]$/,qw(swap proc devpts tmpfs));
		for (my $i = 0; $i < @keys; $i++) {
			$fsinfo->{$vals[0]}->{$keys[$i]} = $vals[$i];
		}
	}
	close(FSTAB);

	# Read the mtab
	open(MTAB,"<$mtab");
	while (<MTAB>) {
		next if /^\s*\#/;
		my @vals = split(/\s+/, $_);
		delete $fsinfo->{$vals[0]}->{unmounted} if exists $fsinfo->{$vals[0]}->{unmounted};
		$fsinfo->{$vals[0]}->{mounted} = 1;
		$fsinfo->{$vals[0]}->{mount_point} = $vals[1];
		$fsinfo->{$vals[0]}->{device} = $vals[0];
		$fsinfo->{$vals[0]}->{special} = 1 if grep(/^$vals[2]$/,qw(swap proc devpts tmpfs));
		for (my $i = 0; $i < @keys; $i++) {
			$fsinfo->{$vals[0]}->{$keys[$i]} = $vals[$i];
		}
	}
	close(MTAB);

	return $fsinfo;

}

1;
