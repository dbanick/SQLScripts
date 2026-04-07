USE [msdb]
GO

/****** Object:  Job [Failback mirroring to production]    Script Date: 08/20/2014 13:02:11 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [db@maint]    Script Date: 08/20/2014 13:02:11 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'db@maint' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'db@maint'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Failback mirroring to production', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'-- This script does a failover of all the databases in a database mirroring session where the database is synchronized
-- This is intended to run on the DR server and automatically fail back any databases once the primary is back online (and in sync)', 
		@category_name=N'db@maint', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Failback]    Script Date: 08/20/2014 13:02:11 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Failback', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--	This script does a failover of all the databases 
--		in a database mirroring session where the database is synchronized
--	This is intended to run on the DR server and automatically fail back any 
--		databases once the primary is back online (and in sync)

SET NOCOUNT OFF  
DECLARE @strSQL NVARCHAR(400) --variable for dynamic SQL statement - variable size can change depending on the length of database names 
DECLARE @strDatabasename NVARCHAR(250) --variable for database name 
DECLARE MyCursor CURSOR FOR --used for cursor allocation  
   SELECT name FROM master.sys.databases a 
   INNER JOIN master.sys.database_mirroring b 
   ON a.database_id=b.database_id 
   WHERE NOT b.mirroring_guid IS NULL -- only mirrored databases
   AND b.mirroring_role_desc=''PRINCIPAL'' -- where the database is currently primary/principal
   and b.mirroring_state = 4 -- and the mirror is in sync/able to be failed over
OPEN MyCursor  
FETCH Next FROM MyCursor INTO @strDatabasename  
WHILE @@Fetch_Status = 0  
BEGIN  
   ---Run the ALTER DATABASE databaseName SET PARTNER FAILOVER command
   SET @strSQL = ''ALTER DATABASE ['' + @strDatabaseName + ''] SET PARTNER FAILOVER''  
   EXEC sp_executesql @strSQL  
   print @strSQL
   PRINT ''Failing over '' + @strDatabaseName  
   PRINT ''========================================''     
FETCH Next FROM MyCursor INTO @strDatabasename  
END   
CLOSE MyCursor  
DEALLOCATE MyCursor  
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Failback mirroring if prod is up', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140711, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'5d7e7230-089d-42a1-96f3-4e1127c8b8ce'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


