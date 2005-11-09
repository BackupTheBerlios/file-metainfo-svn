#!/usr/bin/perl
#

use DBI;
my $dbh=DBI->connect("dbi:SQLite:dbname=test.db","","")|| die "$!\n";
$dbh->do(qq{
	CREATE TABLE test(
		FIELD1 VARCHAR(20),
		FILED2 VARCHAR(20)
		);
	});

print $dbh->func('last_insert_rowid') . "\n";

$dbh->do(qq{
	INSERT INTO test VALUES ("row1_field1","row1_field2")
	});

print $dbh->func('last_insert_rowid') . "\n";

$dbh->do(qq{
	INSERT INTO test VALUES ("row2_field1","row2_field2")
	});

print $dbh->func('last_insert_rowid') . "\n";
