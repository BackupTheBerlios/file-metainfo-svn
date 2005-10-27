#!/usr/bin/perl
#
package main;
use strict;
use Gtk2 -init;
use Gtk2::GladeXML;
use Gnome2;

Gnome2::Program->init ("test", "0.1");
my $app = Gnome2::App->new ("test");
my $gladexml = Gtk2::GladeXML->new("$ARGV[0]");
$gladexml->signal_autoconnect_from_package('main');
my $quitbtn = $gladexml->get_widget('Quit');
Gtk2->main;

sub on_quit1_activate{
	Gtk2->main_quit;
}
