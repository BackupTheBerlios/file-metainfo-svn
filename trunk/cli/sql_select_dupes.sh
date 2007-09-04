sqlite3 ~/.FileInfo/FileInfo.db "select distinct c3.filepath, c3.filename,c1.value from keywords c1, keywords c2, file c3 where c1.keyword='md5' and c2.keyword='md5' and c1.value <> '1B2M2Y8AsgTpgAmY7PhCfg' and c1.value = c2.value and c1.file_id=c3.rowid and c1.file_id <> c2.file_id"

