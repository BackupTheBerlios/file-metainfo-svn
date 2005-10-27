#DB="files.db:FILE keywords.db:KEYWORDS labels.db:LABELS"
DB="FileInfo.db:FILE FileInfo.db:KEYWORDS FileInfo.db:LABELS FileInfo.db:STATUS FileInfo.db:PLUGINS"
for db in $DB; do
	echo "#DUMPING $db"
	d=`echo $db | cut -d ':' -f 1`
	t=`echo $db | cut -d ':' -f 2`
	sqlite3 $@ ~/.FileInfo/$d "SELECT * FROM $t"
done
