#!/usr/bin/perl

use strict;
use warnings;
use Gnome2::VFS -init;
use Gtk2 -init;

my $iconSize=16;
my $iconInfo;

my $iconName = shift;
my $iconTheme= Gtk2::IconTheme->get_default;
if ($iconTheme && $iconTheme->has_icon($iconName)){
                $iconInfo = $iconTheme->lookup_icon($iconName,$iconSize,'use-builtin');
}

die 'Cannot find icon info' unless $iconInfo;

print "display name=" . $iconInfo->get_display_name . "\n";
print "filename=" . $iconInfo->get_filename . "\n";
print "base size=" . $iconInfo->get_base_size . "\n";
