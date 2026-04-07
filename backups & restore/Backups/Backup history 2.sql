set nocount on
DECLARE @dbname varchar(100)
DECLARE @backupdate datetime
DECLARE @logdate datetime
DECLARE @recmodel varchar(15)
create table #Backup (
	dbName varchar(100),
	BackupDate varchar(20)null,
	LogBackupDate varchar(20)null,
	RecoveryModel varchar(15))

declare dbcursor CURSOR for SELECT name FROM master..sysdatabases
Open dbcursor

Fetch next from dbcursor
into @dbname

WHILE @@FETCH_STATUS = 0
	BEGIN 
		USE msdb
		set @backupdate = (SELECT TOP 1 cast(backup_start_date as varchar)
		FROM backupset where database_name = @dbname
		and (type = 'D')
		ORDER BY  backup_start_date DESC)

		set @recmodel = (select CAST(DATABASEPROPERTYEX(@dbname, 'Recovery')as varchar(15)))

		set @logdate = (SELECT TOP 1 cast(backup_start_date as varchar)
		FROM backupset where database_name = @dbname
		and (type = 'L')
		ORDER BY  backup_start_date DESC)
		
		insert #Backup
		VALUES (@dbname, @backupdate, @logdate, @recmodel)
		
		Fetch next from dbcursor
		into @dbname
	END
update #Backup
set BackupDate = 'None' where BackupDate IS NULL
update #Backup
set LogBackupDate = 'None' where LogBackupDate IS NULL
select * from #Backup --where BackupDate = 'None' or LogBackupDate = 'None'
order by BackupDate
drop table #Backup
CLOSE dbcursor
DEALLOCATE dbcursor