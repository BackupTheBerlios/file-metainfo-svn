#!/usr/bin/perl
#
package main;
use strict;
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::Ex::Simple::Tree;
use Glib qw(TRUE FALSE);
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

my $screen=Gtk2::Gdk::Screen->get_default;
my $window=new Gtk2::Window;
$window->signal_connect('destroy',\&_destroy);
my $hbox=new Gtk2::HBox;

my $treestore = Gtk2::TreeStore->new(qw/Glib::String/);
my $treeview = Gtk2::TreeView->new_with_model($treestore);
$treestore->clear();

$treeview->insert_column_with_attributes(
	0,
	'document',
	Gtk2::CellRendererText->new,
	text => 0,
);

my $parent_iter = $treestore->append(undef);
$treestore->set($parent_iter,0,"data0");
my $child_iter=$treestore->append($parent_iter);
$treestore->set($child_iter,0,"data0:1");
my $parent_iter = $treestore->append(undef);
$treestore->set($parent_iter,0,"data1");
my $child_iter=$treestore->append($parent_iter);
$treestore->set($child_iter,0,"data1:1");


warn dmsg . "treestore=" . Dumper($treestore);


#$treeview->set_enable_search(TRUE);
#$treeview->set_headers_clickable(TRUE);
#$treeview->set_rules_hint(TRUE);
#$treeview->set_reorderable(TRUE);
#$treeview->set_search_column(0);

$treestore->foreach(sub { 
		my $ls=shift;
		my $tp=shift;
		my $ti=shift;
		warn dmsg . "\nListStore=" . Dumper($ls) .
			    "TreePath=" . Dumper($tp) . 
			    "TreeIter=" . Dumper($ti);
		my @values=$ls->get($ti);
		warn dmsg . "Value=@values";
		return undef;
	});

warn dmsg . "End walk";

$hbox->add($treeview);
$window->add($hbox);
$window->show_all();

Gtk2->main; # Main loop
warn dmsg "- Exiting" if $debug;
1;

#### Callback ###

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

#################

