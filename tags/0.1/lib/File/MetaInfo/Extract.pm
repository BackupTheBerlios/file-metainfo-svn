#!/usr/bin/perl

package File::MetaInfo::Extract;

=head1 NAME

File::MetaInfo::Extractor - Generic Extract class for File::MetaInfo. Used only to document which methods 
a plugin must have andwhat is expected to return

=head1 SYNOPSIS



=head1 CONTENTS



=item C<new>

   my $plugin_instance = new File::MetaInfo::Extractor::APlugin($filename)
   
Takes a filename as parameter
   
=cut


sub new{
	my $this=shift;
    my $class=ref($this) || $this;
	my $filename=shift;
	#takes the 
	#retur
}


=item C<extract>

   my $plugin_instance = new File::MetaInfo::Extractor::APlugin($filename)
   my $hashref = $pluing_instance->extract();
   
Do the extraction work. Returns an hashref where each value is an array of values.

Example: 

   $VAR1 = {
          'creator' => [
                         'LaTeX with hyperref package'
                       ],
          'format' => [
                        'PDF 1,0'
                      ],
          'producer' => [
                          'pdfTeX-1.10b'
                        ],
          'mimetype' => [
                          'application/pdf'
                        ],
          'page count' => [
                            '55'
                          ],
          'creation date' => [
                               '20040414071800'
                             ]
        };

=cut

sub describe{
	my $self=shift;
	my $class=ref($self)|| $self;
	print "Class: \"$class\" Instance: \"$self\"\n";
}

sub register{
	use File::MetaInfo::DB;
    my $packname = shift;
	my $debug=shift || 0;
	my $db=new File::MetaInfo::DB(debug=>$debug);
	print "Registering \"$packname\"\n";
	my $rc=$db->register($packname);
    $db->close();
	print Dumper($rc) if ($debug);
	$rc or warn "Warning: Could not register \"$packname\": already registered?\n";

    print "Registered \"$packname\": $rc\n";
}

sub test{
	use Data::Dumper;
	my $self=shift;
	my $class=ref($self)|| $self;
	my $file=shift;
	my $debug=shift;
	
	my $p=$class->new($file, debug => $debug);
	
	print "Class: $class\n";
	my $f_desc=$p->can("describe");
	if (!defined($f_desc)){
		print "$f_desc not defined\n";
	}
	else{
		$p->describe();
	}
	print "Dumping extracted data for $file:\n";
    print Dumper($p->extract());
	
}

1
