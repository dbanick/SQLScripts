--Backup all databases that are not offline

DECLARE @dbname varchar(255)
declare @BackupFile varchar(4000), @BackupDir varchar(4000), @cmd varchar(4000), @CreateSub bit

set @BackupDir = 'E:\_SQLBackup\_Test\' -- Set to backup directory
SET @CreateSub = 0  -- Set to 1 if you want the databases backed up to their own sub-directory

declare dbcursor CURSOR for SELECT name FROM master..sysdatabases where name not in('tempdb', 'master', 'model', 'msdb') and DATABASEPROPERTYEX(name, 'Status') != 'OFFLINE'
Open dbcursor

Fetch next from dbcursor
into @dbname

WHILE @@FETCH_STATUS = 0
	BEGIN 
	SET @BackupFile = ''
	If @CreateSub = 1
		BEGIN
		Set @BackupFile = @dbname+'\'
		END
	set @BackupFile = @BackupFile+@dbname+'_db_'
	set @BackupFile = @BackupFile+(select substring(replace(replace(replace(convert(varchar(100),getdate(),120),'-',''),' ',''),':',''),1,len(replace(replace(replace(convert(varchar(100),getdate(),120),'-',''),' ',''),':',''))-2))
	set @BackupFile = @BackupFile+'.bak'
	set @BackupFile = @BackupDir+@BackupFile
	--select @BackupFile --debug

	Set @cmd ='backup database ['+@dbname+'] to disk = '''+@BackupFile+''' with stats = 10'
	select @cmd --debug
	--exec(@cmd)


	Fetch next from dbcursor
		into @dbname
	END
CLOSE dbcursor
DEALLOCATE dbcursor
go