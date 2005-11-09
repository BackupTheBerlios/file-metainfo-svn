if [ -x setenv.sh ]; then
	. setenv.sh
else 
	echo "No setenv.sh"
	exit 1
fi
echo "Registering plugins"
perl -I$FILEMETAINFO_LIBDIR -MFile::MetaInfo::Extract::Keywords -e "File::MetaInfo::Extract::Keywords->register($1);"
perl -I$FILEMETAINFO_LIBDIR -MFile::MetaInfo::Extract::Nautilus -e "File::MetaInfo::Extract::Nautilus->register($1);"
perl -I$FILEMETAINFO_LIBDIR -MFile::MetaInfo::Extract::MD5 -e "File::MetaInfo::Extract::MD5->register($1);"
perl -I$FILEMETAINFO_LIBDIR -MFile::MetaInfo::Extract::MimeType -e "File::MetaInfo::Extract::MimeType->register($1);"

echo "Creating nautilus scripts"
NAUTILUS_SCRIPTNAME='Add Label...'
[ -L "$HOME/.gnome2/nautilus-scripts/$NAUTILUS_SCRIPTNAME" ] && rm "$HOME/.gnome2/nautilus-scripts/$NAUTILUS_SCRIPTNAME"
cat $FILEMETAINFO_BASEDIR/scripts/UI/gnome-metainfo-add | sed s#\$ENV\{FILEMETAINFO_BASEDIR\}#$FILEMETAINFO_BASEDIR# > "$HOME/.gnome2/nautilus-scripts/$NAUTILUS_SCRIPTNAME"
chmod u+x "$HOME/.gnome2/nautilus-scripts/$NAUTILUS_SCRIPTNAME"

