#!/usr/bin/perl

package File::MetaInfo::DB;

use strict;
use warnings;
use DBI;
use File::Basename;
use Carp;

our $AutoLabel;
our $UserLabel;

our $LabelledStatus;
our $KeywordStatus;

#$AutoLabel='A';
#$UserLabel='U';
#$LabelledStatus=3;
#$KeywordStatus=5;

#my @StatusFlags=( $LabelledStatus, $KeywordStatus );

my $db="$ENV{HOME}/.File-MetaInfo/File-MetaInfo.db";

my $sqlGetFiles=qq{ SELECT ROWID,FILENAME,FILEPATH FROM FILE };
my $sqlGetFilesID=qq{ SELECT ROWID FROM FILE };
my $sqlGetNameByID=qq{ SELECT FILEPATH,FILENAME FROM FILE WHERE ROWID=? };
my $sqlGetFileByID=qq{ SELECT ROWID,* FROM FILE WHERE ROWID=? };
my $sqlGetFilesByStatus=qq{ SELECT ROWID,* FROM FILE WHERE STATUS=? };
my $sqlGetAllByID=qq{ SELECT * FROM FILE,KEYWORDS WHERE FILE.ROWID=? AND FILE.ROWID=KEYWORDS.FILE_ID};
my $sqlGetIDByName=qq{ SELECT ROWID FROM FILE WHERE FILENAME=? AND FILEPATH=?};
#my $sqlGetLabelsByName=qq{ SELECT LABELS.LABEL FROM LABELS,FILE WHERE LABELS.FILE_ID=FILE.ROWID AND FILE.FILENAME=? AND FILE.FILEPATH=? };
#my $sqlGetLabelsByNameAndType=qq{ SELECT LABELS.LABEL FROM LABELS,FILE WHERE LABELS.FILE_ID=FILE.ROWID AND FILE.FILENAME=? AND FILE.FILEPATH=? AND LABELS.TYPE=? };
my $sqlGetKeywordsForFileID=qq{ SELECT KEYWORD FROM KEYWORDS WHERE FILE_ID=? };
my $sqlGetKeywordsAndValues=qq{ SELECT KEYWORD,VALUE FROM KEYWORDS WHERE FILE_ID=? };
my $sqlGetKeywordsAndValuesID=qq{ SELECT FILE_ID,KEYWORD,VALUE FROM KEYWORDS WHERE FILE_ID=? };
my $sqlInsertFile=qq{ INSERT OR REPLACE INTO FILE (FILENAME, FILEPATH, MTIME, STATUS, VOLUME) VALUES (?,?,?,0,?) };
#my $sqlUpdateFile=qq{ UPDATE FILE SET FILENAME=?, FILEPATH=?, MTIME=?, STATUS=NULL WHERE ROWID=? };
my $sqlResetFileStatus=qq{ UPDATE FILE SET MTIME=?,STATUS='0' WHERE ROWID=? };
#my $sqlInsertLabel=qq{ INSERT INTO LABELS (FILE_ID, LABEL, TYPE) VALUES (?,?,?) };
my $sqlInsertKeywords=qq{ INSERT OR REPLACE INTO KEYWORDS (FILE_ID, KEYWORD, VALUE) VALUES (?, ?, ?) };
my $sqlKeywordCheck=qq{ SELECT * FROM KEYWORDS WHERE FILE_ID="?" AND KEYWORD="?" AND VALUE="?" };

my $sqlUpdateFileStatus=qq{UPDATE FILE SET STATUS=? WHERE ROWID=? };
#my $sqlGetStatusByID=qq{ SELECT STATUS,FILE_ID,MTIME FROM STATUS WHERE (FILE_ID=?) };

#my $sqlGetFilesByStatus=qq{ SELECT DISTINCT FILE.ROWID,FILE.FILENAME,FILE.FILEPATH FROM STATUS,FILE WHERE (FILE.ROWID=STATUS.FILE_ID) AND (STATUS.STATUS=?) };
#my $sqlAddFileToProcess=qq{ INSERT INTO STATUS (FILE_ID,STATUS) VALUES (?,?)};

my $sqlRegisterPlugin=qq{INSERT INTO PLUGINS (NAME) VALUES (?)};
my $sqlPluginID=qq{SELECT ROWID FROM PLUGINS WHERE NAME=?};
my $sqlAllPluginIDs=qq{SELECT ROWID FROM PLUGINS};
my $sqlListPlugins=qq{SELECT NAME FROM PLUGINS};


# 91: file must be an absolute pathname";
# 92: file not present into db";

sub new{
	my $this=shift;
	my $class=ref($this) || $this;
	my %self;
	my %options=@_;
	$self{path}=".";
	$self{debug}=0;
	$self{dbfile}=$db;
	if ( ! -f $db ){
		warn "Database does not exists yet, I'm going to create it!";
		create_db(\%self);
	}


	@self{keys %options} = values %options;
	$self{debug}=0 if ($self{debug} lt 0);

	$self{dbh}= DBI->connect("dbi:SQLite:dbname=$self{dbfile}","","", {
		 PrintError => $self{debug},
		 ShowErrorStatement => 1,
		 RaiseError => 0
	 	}) || warn "$!\n";

	if ($self{measure}){
		use Time::HiRes qw(time);
	}
	
	if ($self{debug}){
		use Data::Dumper;
	}

	my $self = bless \%self, $class;
        return $self;
}

sub get_dbfilename{
	my $self=shift;

	return $self->{dbfile};
}

sub close{
	my $self=shift;

	$self->{dbh}->disconnect;
}

sub create_db{
	my $self=shift;

	mkdir "$ENV{HOME}/.File-MetaInfo";
	`touch $self->{dbfile}`;
	my $dbh= DBI->connect("dbi:SQLite:dbname=$self->{dbfile}","","") || warn "$!\n";
	$dbh->do(qq{
		CREATE TABLE FILE(
			FILENAME VARCHAR(100) NOT NULL,
			FILEPATH VARCHAR(300) NOT NULL,
			MTIME TIMESTAMP,
			VOLUME CHAR(30) DEFAULT "0",
			STATUS CHAR(1),
			PRIMARY KEY ( FILENAME, FILEPATH, VOLUME )
			)
		});

	$dbh->do(qq{
		CREATE TABLE KEYWORDS(
			FILE_ID INTEGER NOT NULL,
			KEYWORD VARCHAR(50),
			VALUE   VARCHAR(100),
			PRIMARY KEY (FILE_ID, KEYWORD, VALUE)
			)
		});
	$dbh->do(qq{
		CREATE TABLE MORE(
			FILE_ID INTEGER NOT NULL,
			A VARCHAR(50),
			B VARCHAR(50),
			C VARCHAR(50),
			D VARCHAR(50),
			E VARCHAR(50),
			F VARCHAR(50),
			PRIMARY KEY (FILE_ID)
			)
		});

	$dbh->do(qq{
		CREATE TABLE VOLUMES(
			VOLUME CHAR(30),
			LABEL VARCHAR(100),
			DESCRIPTION VARCHAR,
			PRIMARY KEY (VOLUME)
			)
		});

    $dbh->do(qq{
    	CREATE TABLE PLUGINS(
    		NAME VARCHAR (50) NOT NULL,
    		KEYWORD VARCHAR (50),
    		PRIMARY KEY (NAME)
    		)
	   	});
};

sub add_volume($$$){
	my $self=shift;
	my $volid=shift;
	my $volname=shift || 'none';

	warn "DEBUG: File::MetaInfo::DB::add_volume($volid,$volname" if $self->{debug};

	my $sqlAddVolume=qq{ INSERT INTO VOLUMES (VOLUME,LABEL) VALUES (?,?) };

	my $rc=$self->{dbh}->do($sqlAddVolume,undef,$volid,$volname);
	$rc or carp "ERROR: DBI (".$self->{dbh}->err."/". $self->{dbh}->state.") $DBI::errstr" if ($self->{debug});
	return $rc;
}

	

sub add_file($$$){
	my $self=shift;
	my $filename=shift;
	my $volid=shift;
	my @fl=($filename);
	return $self->add_files($volid,\@fl);
}

sub add_files($$){
	my $self=shift;
	my $volid=shift || 0;
	my $filelist=shift;
	
	my $ret=0;
	my $time0;
	my @newfiles;
	$time0=time if ($self->{measure});
	warn "DEBUG: filelist=@$filelist" if ($self->{debug});
	my $ac=$self->{dbh}->begin_work();
	my $isth=$self->{dbh}->prepare($sqlInsertFile) || carp_dbh_error($self->{dbh});
	for my $filename (@$filelist){
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
		my $fname=basename($filename);
		my $fpath=dirname($filename);
		carp "DEBUG: Inserting $fname,$fpath,$mtime" if ($self->{debug});
		$ret+=$isth->execute($fname,$fpath,$mtime,$volid) || carp_dbh_error($self->{dbh});
	}
	if (defined($ac) and ($ac eq 1)){
		$self->{dbh}->commit() || carp_dbh_error($self->{dbh});
	}

	warn "TIMES: $ret " . (time - $time0) . "\n" if ($self->{measure});
	return $ret;
}

sub enqueue_files($$){
	warn "File::MetaInfo::DB::enquque_file is deprecated";
#	my $self=shift;
#	my $idlist=shift;
#	my $flaglist=$self->get_plugin_id();
#	my $ret=0;
#	$self->{dbh}->begin_work();
#	my $isth=$self->{dbh}->prepare($sqlAddFileToProcess) || carp "ERROR: ($DBI::err) $DBI::errstr";
#	for my $id (@$idlist){
#		foreach my $s (@$flaglist){
#			my $time=time;
#			carp "DEBUG: $sqlAddFileToProcess, $id, $s" if $self->{debug};
#			$ret+=$isth->execute($id,$s)|| warn "ERROR:  ($DBI::err) $DBI::errstr" ;
#		}
#	}
#	$self->{dbh}->commit() || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
#	return $ret;
}

sub get_file_id($$){
	my $self=shift;
	my $filename=shift;
	my $fname=basename($filename);
	my $fpath=dirname($filename);
	carp "DEBUG (" . $self->{debug} . "): $sqlGetIDByName , $fname, $fpath" if ($self->{debug});
	my $sth=$self->{dbh}->prepare($sqlGetIDByName) || carp "$!";
	$sth->execute($fname,$fpath) || carp "Cannot execute query: $!";
	my $id=$sth->fetchall_arrayref();
	if ($self->{debug}){
		if (defined($id->[0]->[0])){
			warn "DEBUG: id=" . $id->[0]->[0];
		}
		else {
			warn "DEBUG: $filename not present in DB";
		}
	}
	return $id->[0]->[0];
}

sub get_files_id($){
	my $self=shift;

	my @ret;

	carp "DEBUG: $sqlGetFilesID" if ($self->{debug});
	my $sth=$self->{dbh}->prepare($sqlGetFilesID) || carp "$!";
	$sth->execute() || carp "Cannot execute query: $!";
	my $ids=$sth->fetchall_arrayref();
	foreach (@$ids){
		push @ret,$_->[0];
	}
	return \@ret;
}

#sub get_files_id_by_status($){
#	my $self=shift;
#	my $status=shift;
#	my $column='ROWID';
#
#	my @ret;
#
#	my $ret=$self->get_files_column_by_status($status);
#	warn Dumper($ret);
#	return $ret;
#}

sub get_files_arrayref_by_status($$){
	my $self=shift;
	my $status=shift;

	my @ret;

	warn "DEBUG: get_files_column_by_status - $sqlGetFilesByStatus" if ($self->{debug});
	warn "ERROR: get_files_column_by_status - \$status must be defined";
	return undef unless $status;
	my $sth=$self->{dbh}->prepare($sqlGetFilesByStatus);
	return undef unless $sth;
	my $ret1=$sth->execute($status);
	return undef unless $ret1;
	return $sth->fetchall_arrayref();
}

sub get_file_arrayref($$){
	my $self=shift;
	my $id=shift;
	my $sth=$self->{dbh}->prepare($sqlGetFileByID);
	$sth or carp "ERROR: $@";
	$sth or return undef;
	$sth->execute($id) || carp "Cannot execute query: " . $sth->err();
	return $sth->fetchall_arrayref();
}

sub get_file_hashref($$){
	my $self=shift;
	my $id=shift;
	$id or return undef;
	$self->{dbh}->{FetchHashKeyName} = 'NAME_lc';
	my $sth=$self->{dbh}->prepare($sqlGetFileByID);
	$sth or carp "ERROR: $@";
	$sth or return undef;
	$sth->execute($id) || carp "Cannot execute query: " . $sth->err();
	my $hr=$sth->fetchall_hashref('rowid');
	$hr or return undef;
	return $hr->{$id};
}

sub get_file_name($$){
	my $self=shift;
	my $id=shift;
	my $sth=$self->{dbh}->prepare($sqlGetNameByID);
	$sth or carp "ERROR: $@";
	$sth or return undef;
	$sth->execute($id) || carp "Cannot execute query: " . $sth->err();
	my $result=$sth->fetchall_arrayref();
	foreach my $fa (@$result){
		return "$fa->[0]/$fa->[1]";
	}
}

sub list_plugins($){
	my $self=shift;
	
	return $self->{dbh}->selectall_arrayref($sqlListPlugins) || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
}


=item C<get_plugin_id>

	my $arrayref=$File::MetaInfo->get_plugin_id("File::MetaInfo::Plugins::Dummy");	
	my $arrayref=$File::MetaInfo->get_plugin_id();
	
Returns an arrayref containing the ID of the plugin.
	
=cut


sub get_plugin_id($$){
	my $self=shift;
	my $name=shift;
	
	my $sth;
	my $rv;
	
	warn "name=$name" if $self->{debug} && $name;
	
	if ($name){
		warn "DEBUG: $sqlPluginID" if $self->{debug};
		$sth=$self->{dbh}->prepare($sqlPluginID) || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
		$rv=$sth->execute($name) || carp carp "ERROR: DBI ($DBI::err) $DBI::errstr";
	}
	else {
		warn "DEBUG: $sqlAllPluginIDs" if $self->{debug};
		$sth=$self->{dbh}->prepare($sqlAllPluginIDs) || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
		$rv=$sth->execute() || warn "ERROR: DBI ($DBI::err) $DBI::errstr";
		warn "$rv, ". Dumper($sth) if $self->{debug};
	}
	
	my $ret=$sth->fetchall_arrayref();
	warn "DEBUG: get_plugin_id=" . Dumper($ret) if $self->{debug};	
	return $ret;
	
}

sub update_keywords{
	my $self=shift;
	warn "DEBUG: File::MetaInfo::DB::update_keywords(@_)" if $self->{debug};

	my $fileID=shift;
	my $hash=shift;
	my $ret;
	
	if (!defined($fileID)){
		return undef;
	}
	warn "DEBUG: File::MetaInfo::DB AutoCommit=" . $self->{dbh}->{AutoCommit} if ($self->{debug});
	my $ac = $self->{dbh}->begin_work;
	warn "DEBUG: File::MetaInfo::DB ac=$ac AutoCommit=" . $self->{dbh}->{AutoCommit} if ($self->{debug});
	my $sth = $self->{dbh}->prepare($sqlInsertKeywords);
	#warn "DEBUG: File::MetaInfo::DB kv_hash=" . Dumper($hash);
	foreach my $k (keys(%$hash)){
		foreach my $v (@{$hash->{$k}}){
			$ret=$sth->execute($fileID,$k,$v);
  			warn "fileID=$fileID key=$k val=$v ret=$ret\n" if ($self->{debug});
		}
	}
	if (defined($ac) and ($ac eq 1)){
		$self->{dbh}->commit;
		warn "DEBUG: File::MetaInfo::DB commit ac=$ac AutoCommit=" . $self->{dbh}->{AutoCommit} if ($self->{debug});
	}
	return $ret;
}


sub update_status{
	my $self=shift;
	carp "DEBUG: ::update_status(@_)" if $self->{debug};
	my $id=shift;
	my $status=shift;
	my @para;
	return undef unless defined($status);
	warn "DEBUG: $sqlUpdateFileStatus,$status,$id" if ($self->{debug});
	warn "DEBUG: File::MetaInfo::DB AutoCommit=" . $self->{dbh}->{AutoCommit} if ($self->{debug});
	my $ret=$self->{dbh}->do($sqlUpdateFileStatus,undef,$status,$id) || carp_dbh_error($self->{dbh});
	warn "DEBUG: ret=$ret" if ($self->{debug});
	return $ret;
}

sub reset_status{
	my $self=shift;
	my $id=shift;
	my $filename=shift;
	
	my $ret;
	my @stats = stat($filename);
	if (!defined($stats[0])){
		warn "DEBUG: File::MetaInfo::DB - file has been (probably) removed" if ($self->{debug});
		return undef
	}
	else{
		warn "DEBUG: $sqlResetFileStatus,$stats[9],$id" if ($self->{debug});
		warn "DEBUG: File::MetaInfo::DB AutoCommit=" . $self->{dbh}->{AutoCommit} if ($self->{debug});
		$ret=$self->{dbh}->do($sqlResetFileStatus,undef,$stats[9],$id) || carp_dbh_error($self->{dbh});
	}
	return $ret;
}


sub begin_work{
	my $self=shift;
	carp "DEBUG: starting transaction" if $self->{debug};
	return $self->{dbh}->begin_work()|| carp_dbh_error($self->{dbh});
}

sub commit{
	my $self=shift;

	carp "DEBUG: committing transaction" if $self->{debug};
	return $self->{dbh}->commit()|| carp_dbh_error($self->{dbh});
}

sub list_all_keywords{
	my $self=shift;
	
	my $sqlListAllKeywords=qq{ SELECT DISTINCT KEYWORD FROM KEYWORDS };
	carp "DEBUG: $sqlListAllKeywords" if ($self->{debug});
	return $self->{dbh}->selectall_arrayref($sqlListAllKeywords);

}

sub get_keywords{
	my $self=shift;
	my $fileID=shift;
	if (defined($fileID)){
		carp "DEBUG: $sqlGetKeywordsForFileID, $fileID" if ($self->{debug});
		my $sth=$self->{dbh}->prepare($sqlGetKeywordsForFileID) || carp "$!";
		$sth->execute($fileID) || carp "$!";
		return $sth->fetchall_arrayref();
	}
}

sub list_all_values_for_keyword{
	my $self=shift;
	my $keyword=shift;
	
	my $sqlListAllValues=qq{ SELECT DISTINCT VALUE FROM KEYWORDS WHERE KEYWORD='$keyword' };
	carp "DEBUG: $sqlListAllValues" if ($self->{debug});
	return $self->{dbh}->selectall_arrayref($sqlListAllValues);
}

sub list_files_by_keyword{
	my $self=shift;
	my $column=shift || "FILE.ROWID";
	my $keyword=shift;
	my $value=shift;
	my $clause;

	if (defined($keyword)){
		$clause=qq{ KEYWORDS.KEYWORD='$keyword' };;
	}
	if (defined($value)){
		$clause=join(' AND ', $clause, qq{ KEYWORDS.VALUE='$value' });
	}

	my $sqlListFiles=qq{ SELECT DISTINCT $column FROM FILE,KEYWORDS WHERE FILE.ROWID=KEYWORDS.FILE_ID AND $clause };
	carp "DEBUG: $sqlListFiles" if ($self->{debug});
	return $self->{dbh}->selectall_arrayref($sqlListFiles);

}


sub get_values{
	my $self=shift;
	my $fileID=shift;
	if (defined($fileID)){
		carp "DEBUG File::MetaInfo::DB: $sqlGetKeywordsAndValues, $fileID" if ($self->{debug});
		my $sth=$self->{dbh}->prepare($sqlGetKeywordsAndValues) || carp "$!";
		$sth->execute($fileID) || carp "$!";
		return $sth->fetchall_arrayref();
	}
}

sub get_values_hashref{
	my $self=shift;
	my $fileID=shift;
	if (defined($fileID)){
		my $arrayref=$self->get_values($fileID);
		my %h;
		foreach (@$arrayref){
			#if (defined($h{$_->[0]})){
				push @{$h{$_->[0]}},$_->[1];
				#}
				#else {
				#$h{$_->[0]}=$_->[1];
				#}
		}
		#warn Dumper(\%h) if ($self->{debug});
		return \%h;
	}
}

sub exec_sql{
	my $self=shift;
	my $sql=shift;
	carp "DEBUG File::MetaInfo::DB: sql=$sql" if $self->{debug};
	my $sth=$self->{dbh}->prepare($sql);
	$sth or carp "ERROR File::MetaInfo::DB: DBI (".$self->{dbh}->err."/". $self->{dbh}->state.") $DBI::errstr" if ($self->{debug});
	my $rc=$sth->execute();
	$rc or carp "ERROR File::MetaInfo::DB: DBI (".$self->{dbh}->err."/". $self->{dbh}->state.") $DBI::errstr" if ($self->{debug});
	return $sth->fetchall_arrayref();
}

sub create_view{
	my $self=shift;
	my $name=shift;
	my $select=shift;

	warn "DEBUG: File::MetaInfo::DB::create_view $name sql=\'$select\'" if $self->{debug};
	push @{$self->{views}},$name;
	my $sql=qq{ CREATE TEMPORARY VIEW $name AS $select};
	my $ret=$self->{dbh}->do($sql);
	$ret or carp "ERROR: DBI (".$self->{dbh}->err."/". $self->{dbh}->state.") $DBI::errstr" if ($self->{debug});
	return $ret;
}

sub drop_view{
	my $self=shift;
	my $name=shift;
	delete $self->{views}->{$name};
	my $sql=qq{ DROP VIEW $name};
	return $self->{dbh}->do($sql);
}

sub process_all_files{
	warn "WARNING: File::MetaInfo::DB::process_all_files is deprecated!\n";
#	my $self=shift;
#	carp "DEBUG: ::process_all_files(@_)" if $self->{debug};
#	my $proc=shift;
#	my $flag=shift;
#	my $param=shift || '';
#	
#	my $isth;
#	my $r;
#	if (!defined($flag)){
#		$flag=9999;
#		carp "DEBUG: $sqlGetFiles, status=$flag" if ($self->{debug});
#		$isth=$self->{dbh}->prepare($sqlGetFiles) || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
#		$r=$isth->execute();
#	}
#	else {
#		carp "DEBUG: $sqlGetFilesByStatus, status=$flag" if ($self->{debug});
#		$isth=$self->{dbh}->prepare($sqlGetFilesByStatus) || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
#		$r=$isth->execute($flag);
#	}
#	return $r unless $r;
#	my $rowref;
#	my $i=0;
#	while ($rowref=$isth->fetchrow_arrayref){
#		carp "DEBUG: rowref=(@$rowref),$flag,$param" if ($self->{debug});
#		#$rowref columns are: ID,FILENAME,FILEPATH
#		$proc->($rowref,$flag,$param);
#
#		#After the file has been processed, update the FILE.UPDTIME
#		if ($flag && ($flag != 9999)){
#			carp "DEBUG: $sqlUpdateFileStatus, ". time . " $rowref->[0]" if ($self->{debug});
#			my $rv=$self->{dbh}->do($sqlUpdateFileStatus,undef,time,$rowref->[0]) || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
#		}
#		$i++;
#	}
#	return $i;
}

sub check{
	my $self=shift;
	carp "DEBUG: File::MetaInfo::DB::check(@_)" if $self->{debug};
	
	my $now=time;

	#"SELECT FILE.ROWID FROM FILE WHERE (FILE.UPDTIME < ?) OR (FILE.UPDTIME ISNULL)"

}

sub register{
	my $self=shift;
	my $plugin_name=shift;
	
	warn "DEBUG: Registering plugin $plugin_name..." if $self->{debug};
	
	my $rc=$self->{dbh}->do($sqlRegisterPlugin,undef,$plugin_name);
	$rc or carp "ERROR: DBI (".$self->{dbh}->err."/". $self->{dbh}->state.") $DBI::errstr" if ($self->{debug});
	return $rc;
}

sub search{
	my $self=shift;
	my $value=shift;

	my $sqlSearchAll=qq{ SELECT DISTINCT FILE.ROWID FROM FILE,KEYWORDS WHERE ( FILE.ROWID=KEYWORDS.FILE_ID AND 
		( FILE.FILENAME LIKE '%$value%' OR KEYWORDS.VALUE LIKE '%$value%' OR
		  FILE.FILEPATH LIKE '%$value%' OR KEYWORDS.KEYWORD LIKE '%$value%'))};
	return $self->exec_sql($sqlSearchAll);
}

sub search_keyval{
	my $self=shift;
	my $hashref=shift;
    # hashref must be in the folowing format:
    # {
    #    keywords=> "keyword1",
    #	 values=> "value1",
    # }
    #
    
	my $sql=qq{SELECT DISTINCT FILE.ROWID FROM FILE,KEYWORDS WHERE (FILE.ROWID=KEYWORDS.FILE_ID AND ( KEYWORDS.KEYWORD LIKE '%$hashref->{keyword}%' AND KEYWORDS.VALUE LIKE '%$hashref->{value}%')};

	return $self->exec_sql($sql);
}

sub search_custom{
	my $self=shift;
	my $sqlClause=shift;
	
	my $sql=qq{SELECT DISTINCT FILE.ROWID FROM FILE,KEYWORDS WHERE (FILE.ROWID=KEYWORDS.FILE_ID AND ($sqlClause))};
	
	return $self->exec_sql($sql);
}

sub stats{
	my $self=shift;
	my %hret;
	
	my $sqlCountFiles=qq{SELECT COUNT(ROWID) FROM FILE};
	my $arrayref=$self->exec_sql($sqlCountFiles);
	warn "DEBUG: $sqlCountFiles = ", Dumper($arrayref) if $self->{debug};
	$hret{files}=$arrayref->[0]->[0];

	my $sqlCountKeywords=qq{SELECT COUNT(ROWID) FROM KEYWORDS};
	$arrayref=$self->exec_sql($sqlCountKeywords);
	warn "DEBUG: $sqlCountKeywords = ", Dumper($arrayref) if $self->{debug};
	$hret{keywords}=$arrayref->[0]->[0];

	$hret{dbsize}=`du -k $self->{dbfile} | cut -f 1`;
	chomp $hret{dbsize};
	warn "DEBUG: stats=" . Dumper (\%hret) if $self->{debug};
	return \%hret;
}

sub carp_dbh_error{
	my $dbh=shift;

	carp "ERROR: DBI (" . $dbh->err .") " . $dbh->errstr ;
}

sub last_err{
	my $self=shift;

	return $self->{dbh}->err, $self->{dbh}->errstr;
}

#sub _add{
#my $dbh=shift;
#my $table=shift;
#my $columns=shift;
#my $values=shift;
#
#return $dbh->do("INSERT INTO $table ($columns) VALUES ($values)");
#}
#
#sub _select{
#my $dbh=shift;
#my $table=shift;
#my $columns=shift;
#my $clause=shift;
#my $debug=shift || 0;
#
#carp "SELECT $columns FROM $table WHERE $clause" if ($debug);
#return $dbh->selectall_arrayref(qq{
#SELECT $columns FROM $table WHERE $clause
#});
#}
#
#sub add_labels{
#	my $self=shift;
#	carp "DEBUG: ::add_labels(@_)" if $self->{debug};
#	my $fileID=shift;
#	my $labels=shift;
#	my $type=shift;
#	my $r;
#	$self->{dbh}->begin_work();
#	my $isth=$self->{dbh}->prepare($sqlInsertLabel) || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
#	for my $l (@$labels){
#		if ($l !~ /^$/){
#			carp "DEBUG: $sqlInsertLabel,$fileID,$l,$type" if $self->{debug};
#			$r=$isth->execute($fileID,$l,$type) || carp "ERROR: DBI ($DBI::err) $DBI::errstr";
#			carp "DEBUG: execute=<$r>" if $self->{debug};
#		}
#	}
#	$self->{dbh}->commit()|| carp "ERROR: DBI ($DBI::err) $DBI::errstr";
#	return $r;
#}

#sub get_labels_by_name{
#	my $self=shift;
#	my $filename=shift;
#	my $label=shift;
#	my $ltype=shift;
#	my $ltype_clause;
#	my $fname=basename($filename);
#	my $fpath=dirname($filename);
#	if (!defined($ltype)){
#		my $sth=$self->{dbh}->prepare($sqlGetLabelsByName) || carp "$!";
#		$sth->execute($fname,$fpath) || carp "$!";
#		return $sth->fetchall_arrayref();
#	}
#}

#sub add_label{
#	my $self=shift;
#	my $fileID=shift;
#	my $label=shift;
#	my $ltype=shift;
#	if (!defined($fileID)){
#		return undef;
#	}
#	return $self->{dbh}->do($sqlInsertLabel,undef,$fileID,$label,$ltype);
#}


1;
