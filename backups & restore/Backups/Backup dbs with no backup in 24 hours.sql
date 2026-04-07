set nocount on
go
DECLARE @dbname varchar(255)
declare @BackupFile varchar(4000), @BackupDir varchar(4000), @cmd varchar(4000), @CreateSub bit

/********** SET THE BACKUP DIRECTORY HERE ***********/
set @BackupDir = 'F:\Program Files\Microsoft SQL Server\MSSQL\BACKUP\' -- Set to backup directory
SET @CreateSub = 0  -- Set to 1 if you want the databases backed up to their own sub-directory

--requires cleanup
DECLARE @counter SMALLINT
DECLARE @dbnameTable VARCHAR(100)
DECLARE @db_bkpdate varchar(100)
DECLARE @status varchar(20)
DECLARE @svr_name varchar(100)
DECLARE @media_set_id varchar(20)
DECLARE @filepath VARCHAR(1000)
Declare @filestatus int
DECLARE @fileavailable varchar(20)
DECLARE @BACKUPSIZE float

SELECT @counter=MAX(dbid) FROM master..sysdatabases
CREATE TABLE #backup_details (ServerName varchar(100),DatabaseName varchar(100),BkpDate varchar(20) NULL,BackupSize_in_MB varchar(20),Status varchar(20),FilePath varchar(1000),FileAvailable varchar(20))
select @svr_name = CAST(SERVERPROPERTY('ServerName')AS sysname)
WHILE @counter > 0
BEGIN
/* Need to re-initialize all variables*/
Select @dbnameTable = null , @db_bkpdate = null ,
@media_set_id = Null , @backupsize = Null ,
@filepath = Null , @filestatus = Null , 
@fileavailable = Null , @status = Null , @backupsize = Null

select @dbnameTable = name from master..sysdatabases where dbid = @counter
select @db_bkpdate = max(backup_start_date) from msdb..backupset where database_name = @dbnameTable and type='D'
select @media_set_id = media_set_id from msdb..backupset where backup_start_date = ( select max(backup_start_date) from msdb..backupset where database_name = @dbnameTable and type='D')
select @backupsize = backup_size from msdb..backupset where backup_start_date = ( select max(backup_start_date) from msdb..backupset where database_name = @dbnameTable and type='D')
select @filepath = physical_device_name from msdb..backupmediafamily where media_set_id = @media_set_id
EXEC master..xp_fileexist @filepath , @filestatus out
if @filestatus = 1
set @fileavailable = 'Available'
else
set @fileavailable = 'NOT Available'
if (datediff(day,@db_bkpdate,getdate()) > 7)
set @status = 'Warning'
else
set @status = 'Healthy'
set @backupsize = (@backupsize/1024)/1024
insert into #backup_details select @svr_name,@dbnameTable,@db_bkpdate,@backupsize,@status,@filepath,@fileavailable
update #backup_details
set status = 'Warning' where bkpdate IS NULL
set @counter = @counter - 1
END
--cleanup above

/******************/
declare dbcursor CURSOR for 

select DatabaseName from #backup_details where databasename not in ('tempdb')
AND BkpDate < GETDATE()-1
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

drop table #backup_details
set nocount off
go
