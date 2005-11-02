perl -I$FILEMETAINFO_LIBDIR -MFile::MetaInfo::Extract::Keywords -e "File::MetaInfo::Extract::Keywords->register($1);"
perl -I$FILEMETAINFO_LIBDIR -MFile::MetaInfo::Extract::Nautilus -e "File::MetaInfo::Extract::Nautilus->register($1);"
perl -I$FILEMETAINFO_LIBDIR -MFile::MetaInfo::Extract::MD5 -e "File::MetaInfo::Extract::MD5->register($1);"
perl -I$FILEMETAINFO_LIBDIR -MFile::MetaInfo::Extract::MimeType -e "File::MetaInfo::Extract::MimeType->register($1);"
