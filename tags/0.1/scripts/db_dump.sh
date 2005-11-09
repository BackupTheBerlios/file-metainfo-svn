#DB="files.db:FILE keywords.db:KEYWORDS labels.db:LABELS"
DB="File-MetaInfo.db:FILE File-MetaInfo.db:KEYWORDS File-MetaInfo.db:LABELS File-MetaInfo.db:STATUS File-MetaInfo.db:PLUGINS"
for db in $DB; do
	echo "#DUMPING $db"
	d=`echo $db | cut -d ':' -f 1`
	t=`echo $db | cut -d ':' -f 2`
	sqlite3 $@ ~/.File-MetaInfo/$d "SELECT * FROM $t"
done
