#!/usr/bin/perl -I /home/developement/glocate/
#
package main;
use strict;
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::SimpleList;
use Gnome2;
use Data::Dumper;
use Getopt::Long;

my $debug;
my $uifile="%FILENAME%.glade";
my $myname="";
my $version="0.0";

sub dmsg{ return "*** DEBUG [$myname]: @_" };

################################
# Options parsing and settings #
################################

GetOptions(
	"debug" => \$debug
);

#########################################
# Glade UI loading and application init #
#########################################

#Gnome2::Program->init ($myname, $version);
my $screen=Gtk2::Gdk::Screen->get_default;
#my $app = Gnome2::App->new ("GFileInfo/Simple");
my $gladexml = Gtk2::GladeXML->new($uifile);
$gladexml->signal_autoconnect_from_package('main');

Gtk2->main; # Main loop
warn dmsg "- Exiting" if $debug;
1;

#############
# Callbacks #
#############

sub on_quit1_activate{
	print "SIGNAL: on_quit1_activate\n";
	Gtk2->main_quit;
}


sub on_%NAME%_destroy
{
        Gtk2->main_quit;
	1;
}

sub gtk_main_quit
{
        Gtk2->main_quit;
	1;
}

##################


