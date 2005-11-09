#!/usr/bin/perl
#
package main;
use strict;
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::SimpleList;
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

my $liststore=new Gtk2::ListStore(
	'Glib::String',
	'Glib::String',
	'Glib::String');


my $col0='Col0Row0';
my $col1='Col1Row0';
my $col2='Col2Row0';

$liststore->set($liststore->append(),
	0,$col0,
	1,$col1,
	2,$col2);

my $col0='Col0Row1';
my $col1='Col1Row1';
my $col2='Col2Row1';


$liststore->set($liststore->append(),
	0,$col0,
	1,$col1,
	2,$col2);

warn dmsg . "liststore=" . Dumper($liststore);

my $treeview=Gtk2::TreeView->new_with_model($liststore);

my $tvcolumn0=Gtk2::TreeViewColumn->new_with_attributes("Col0",new Gtk2::CellRendererText,"text",0);
$tvcolumn0->set_sizing('fixed');
$tvcolumn0->set_fixed_width(100);
$tvcolumn0->set_sort_column_id(0);
$treeview->append_column($tvcolumn0);

my $tvcolumn1=Gtk2::TreeViewColumn->new_with_attributes("Col1",new Gtk2::CellRendererText,"text",1);
$tvcolumn1->set_sizing('fixed');
$tvcolumn1->set_fixed_width(100);
$tvcolumn0->set_sort_column_id(1);
$treeview->append_column($tvcolumn1);

$treeview->set_enable_search(TRUE);
$treeview->set_headers_clickable(TRUE);
$treeview->set_rules_hint(TRUE);
$treeview->set_reorderable(TRUE);
$treeview->set_search_column(0);

$liststore->foreach(sub { 
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

