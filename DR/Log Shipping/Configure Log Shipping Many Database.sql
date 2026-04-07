SET NOCOUNT ON

/* -- Declare Variables */
DECLARE @Primary varchar(255)
DECLARE @dbname varchar(255)
DECLARE @LS_BackupJobId AS uniqueidentifier 
DECLARE @LS_PrimaryId AS uniqueidentifier 
DECLARE @BackupPath varchar(500) -- Local Path to backups
DECLARE @BackupShare varchar(500) -- Network Path to backups
DECLARE @BackupJobName varchar(500)
DECLARE @BackupFile varchar(4000)
DECLARE @cmdBackup varchar(4000)
DECLARE @cmdBackupLog varchar(4000)
DECLARE @cmdLS varchar(max)
DECLARE @cmdSchedule varchar(8000)
DECLARE @cmdEnable varchar(4000)
DECLARE @cmdAlert varchar(400)
DECLARE @exec bit

/* -- Set initial variables and backup locations */
SET @Primary = (SELECT @@SERVERNAME)
SET @BackupPath = 'E:\_SQLBackup\_Test\' -- Set to backup directory, local to primary
SET @BackupShare = 'E:\_SQLBackup\_Test\' -- Set to backup directory, network path accessible 
SET @exec = 0 -- if 0, don't execute only print, if 1, then execute and print

/* Create temp table to hold our commands */
CREATE TABLE #Commands (
ID int identity (1,1),
CMD varchar(max)
)

declare dbcursor CURSOR for SELECT name FROM master..sysdatabases 
	where name not in('tempdb', 'master', 'model', 'msdb') -- add any databases you don't want to LS here
	and DATABASEPROPERTYEX(name, 'Status') != 'OFFLINE'
Open dbcursor

Fetch next from dbcursor
into @dbname

WHILE @@FETCH_STATUS = 0
	BEGIN 

		/* Backup Database */
		---------------------
		SET @BackupFile = ''
		set @BackupFile = @BackupFile+@dbname
		set @BackupFile = @BackupFile+'.bak'
		set @BackupFile = @BackupPath+@BackupFile
		Set @cmdBackup ='backup database ['+@dbname+'] to disk = '''+@BackupFile+''' with stats = 10'
		
		Insert into #Commands
			select @cmdBackup --debug
		if @exec = 1
			exec(@cmdBackup)
		---------------------

		/* Backup Database Log */
		-------------------------
		SET @BackupFile = ''
		set @BackupFile = @BackupFile+@dbname
		set @BackupFile = @BackupFile+'.trn'
		set @BackupFile = @BackupPath+@BackupFile
		Set @cmdBackupLog ='backup log ['+@dbname+'] to disk = '''+@BackupFile+''' with stats = 10'
		
		Insert into #Commands
			select @cmdBackupLog --debug
		if @exec = 1
			exec(@cmdBackupLog)
		-------------------------
		
		/* Set job name for each database */
		------------------------------------
		SET @BackupJobName = 'LSBackup_' + @dbName
		------------------------------------
		
		/* Configure Primary for LS */
		-----------------------------
		SET @cmdLS ='EXEC sp_add_log_shipping_primary_database @database = ''' + @dbName + ''',@backup_directory = ''' + @BackupPath  + ''',@backup_share = ''' + @BackupShare  + ''',@backup_job_name = ''' + @BackupJobName + ''',@backup_retention_period = 1440 ,@monitor_server = ''' + @Primary + ''',@monitor_server_security_mode = 1,@backup_threshold = 60,@threshold_alert = 0,@threshold_alert_enabled = 0,@history_retention_period= 1440,@backup_compression = 0 '      
		
		Insert into #Commands
			SELECT @cmdLS --debug
		if @exec = 1
			exec(@cmdLS)
		------------------------------

		/* Add a schedule for the backup job. */
		----------------------------------------
		set @cmdSchedule = 'EXEC msdb.dbo.sp_add_jobschedule @job_name = ''' + @BackupJobName + ''',@name= ''' + @BackupJobName + ''',@enabled=1,@freq_type=4,@freq_interval=1,@freq_subday_type=4,@freq_subday_interval=15,@freq_relative_interval=0,@freq_recurrence_factor=1,@active_start_date=20140501,@active_end_date=99991231,@active_start_time=0,@active_end_time=235959'
		
		Insert into #Commands
			SELECT @cmdSchedule --debug
		if @exec = 1
			exec(@cmdSchedule)
		----------------------------------------             

		/* Enable the backup job. */
		----------------------------
		SET @cmdEnable = 'EXEC dbo.sp_update_job @job_name = ''' + @BackupJobName + ''',@enabled = 1'
		
		Insert into #Commands
			SELECT @cmdEnable --debug
		if @exec = 1
			exec(@cmdEnable)
		----------------------------


		Fetch next from dbcursor
		into @dbname
	END

CLOSE dbcursor
DEALLOCATE dbcursor

/* Add monitor alert job (1 time) */
------------------------------------
SET @cmdAlert = 'EXEC sp_add_log_shipping_alert_job;'

Insert into #Commands
	SELECT @cmdAlert --debug
if @exec = 1
	exec(@cmdAlert)
------------------------------------

select * from #Commands
GO
DROP TABLE #Commands
GO


--optional parameters for these SP's, not sure if we want to do any validation with these, but I excluded for now.
--@backup_job_id = @LS_BackupJobId OUTPUT,@primary_id = @LS_PrimaryId OUTPUT,
--,@schedule_id = @schedule_id OUTPUT