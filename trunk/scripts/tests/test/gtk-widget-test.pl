#!/usr/bin/perl -I /home/developement/glocate/
#
package main;
use strict;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::SimpleList;
use Gnome2;
use Data::Dumper;
use Getopt::Long;
use FileInfo;
use FileInfo:DB;

my $debug;
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

my $screen = Gtk2::Gdk::Screen->get_default;
my $window = Gtk2::Window->new ('toplevel');
my $viewport = Gtk2::ScrolledWindow->new();
my $treeview = Gtk2::TreeView->new();

$window->signal_connect('destroy',\&_destroy);

my $liststore=Gtk2::SimpleList->new_from_treeview (
		$treeview,
                'Bool Field'    => 'bool',
                'Text Field'    => 'text',
);

my $fdb=new FileInfo::DB( debug => $debug ) || die "Could not open db";
my $aref=$fdb->list_all_keywords();

foreach my $kw (@{$aref->[0]}){
	@{$liststore->{data}} = (
          	[ TRUE, $kw ],
	);
}

$viewport->add($treeview);
$window->add($viewport);
$window->show_all;

Gtk2->main; # Main loop
warn dmsg "- Exiting" if $debug;
$fdb->close();
1;

#############
# Callbacks #
#############

sub _destroy
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


