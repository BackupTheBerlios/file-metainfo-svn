#!/usr/bin/perl

use strict;
use XML::Simple;
use Data::Dumper;
use File::Basename;
use Cwd qq{abs_path};

my $file=shift;
my $METAFILESDIR=$ENV{HOME} . "/.nautilus/metafiles";
my $xs1 = XML::Simple->new();

my $fileurl=lc ("//" . abs_path(dirname $file));
my $name=basename($file);
$fileurl =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
$fileurl = "file:" . $fileurl . ".xml";

my $metafile="$METAFILESDIR/$fileurl";

print "metafile: $metafile\n";

my $doc = $xs1->XMLin($metafile);

print "#####DUMP####\n";
#print  Dumper($doc->{file}->{$name}->{keyword});
print  Dumper($doc->{file});
print "#############\n";

foreach my $key (keys (%{$doc->{file}})){
   print "$key: ";
   print $doc->{file}->{$key}->{keyword}->{name} . "\n";
}


