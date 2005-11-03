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
use FileInfo;

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
my $window=new Gtk2::Window;
my $hbox=new Gtk2::HBox;
my $optionmenu=new Gtk2::OptionMenu();

$hbox->add($optionmenu);
$window->add($hbox);
$window->show_all();

Gtk2->main; # Main loop
warn dmsg "- Exiting" if $debug;
1;

