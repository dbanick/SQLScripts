USE [msdb]
GO

/****** Object:  Job [Resync logins]    Script Date: 08/20/2014 13:02:52 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/20/2014 13:02:52 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Resync logins', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Resync Logins for All Databases]    Script Date: 08/20/2014 13:02:52 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Resync Logins for All Databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
SET QUOTED_IDENTIFIER OFF
use msdb
exec sp_MSforeachdb
"
use [?]
 IF ''[?]'' NOT IN (''tempdb'')

SET NOCOUNT ON
 
DECLARE @user varchar(30),@message varchar(500) 
DECLARE user_cursor CURSOR FOR 
SELECT name
FROM sysusers
where islogin = 1 and issqluser = 1 and name not in (''dbo'',''guest'')
ORDER BY name
 
OPEN user_cursor
 
FETCH NEXT FROM user_cursor 
INTO @user
 
WHILE @@FETCH_STATUS = 0
BEGIN
   
      If exists (Select name from master.dbo.syslogins where name = @user)
       BEGIN
         SELECT @message = ''sp_change_users_login '' + '''''''' + ''Update_One'' + '''''''' + '','' + '''''''' +  @user + '''''''' + '' , '' + '''''''' + @user + ''''''''
         select @message
         exec (@message) 
       END
   
  
   -- Get the next user.
   FETCH NEXT FROM user_cursor 
   INTO @user
END
 
CLOSE user_cursor
DEALLOCATE user_cursor
"
SET QUOTED_IDENTIFIER ON', 
		@database_name=N'master', 
		@output_file_name=N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\SyncUsers.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Resync Login', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140819, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'924cb642-d2db-4d54-914c-21b2272122e0'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


