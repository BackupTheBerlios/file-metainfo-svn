#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Gtk2 -init;
use Data::Dumper;

my $theme=Gtk2::IconTheme->get_default;

print Dumper($theme);
my @sp=$theme->get_search_path;
print "search_path: @sp\n";
#my @il=$theme->list_icons(undef);
#print "icons: " . $theme->list_icons . "\n";

