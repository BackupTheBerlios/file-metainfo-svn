#!/usr/bin/perl

use strict;
use warnings;
use Gnome2::VFS -init;
use Gtk2 -init;

my $fn=shift;
my $iconInfo;
my $iconPixbuf;
my $iconSize=16;
my $gmi;
my %mimeinfo;

my $mime=Gnome2::VFS->get_mime_type($fn);
my $mime_type = new Gnome2::VFS::Mime::Type($mime);
my $applist = $mime_type->get_all_applications();
my $application = $mime_type->get_default_application();
my $mimeactiontype = $mime_type->get_default_action_type();
my $iconName = $mime_type->get_icon();
if (!$iconName){
	$iconName = "gnome-mime-" . $mime;
	$iconName =~ s#/#-#;
}
my $iconTheme= Gtk2::IconTheme->get_default;
if ($iconTheme && $iconTheme->has_icon($iconName)){
                $iconPixbuf = $iconTheme->load_icon($iconName,$iconSize,'use-builtin');
}
else{
	$mime =~ m#^(.*)/.*$#;
       	$iconName= "gnome-mime-" . $1;
        if ($iconTheme && $iconTheme->has_icon($iconName)){
        	$iconPixbuf = $iconTheme->load_icon($iconName,$iconSize,'use-builtin');
	}
	elsif ($mime =~ /x-directory/){
		$iconName="gnome-fs-directory";
		if ($iconTheme && $iconTheme->has_icon($iconName)){
			$iconPixbuf = $iconTheme->load_icon($iconName,$iconSize,'use-builtin');
		}
	}
}
print "mime action type=$mimeactiontype\n";
print "application=$application\n";
print "applications list=$applist\n";
print "icon name=$iconName\n";
print "icon pixbuf=$iconPixbuf\n";
