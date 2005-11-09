# FileInfo - check module loading and create testing directory

use Test::More tests =>  2 ;

BEGIN { use_ok( 'FileInfo' ); }

my $object = FileInfo->new ();
isa_ok ($object, 'FileInfo');
