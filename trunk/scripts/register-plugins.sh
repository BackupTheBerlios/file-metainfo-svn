perl -I/home/developement/FileInfo/lib -MFileInfo::Plugins::Extract -e "FileInfo::Plugins::Extract->register($1);"
perl -I/home/developement/FileInfo/lib -MFileInfo::Plugins::Nautilus -e "FileInfo::Plugins::Nautilus->register($1);"
perl -I/home/developement/FileInfo/lib -MFileInfo::Plugins::MD5 -e "FileInfo::Plugins::MD5->register($1);"
perl -I/home/developement/FileInfo/lib -MFileInfo::Plugins::MimeType -e "FileInfo::Plugins::MimeType->register($1);"
