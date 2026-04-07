USE [msdb]
GO

/****** Object:  Job [db@maint - Verify Replication Job is Running]    Script Date: 10/06/2011 10:55:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [db@maint]    Script Date: 10/06/2011 10:55:25 ******/


DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Verify MRDB101 Replication Jobs are Running', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job is designed to fail if the Replication job "DB3-FIN-FIN-mrdb101-9" is not running. Please investigate and contact Debi or David if it is stopped.', 
		@category_name=N'REPL-Alert Response', 
		@owner_login_name=N'sa', 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Replication Job]    Script Date: 10/06/2011 10:55:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Replication Job', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use msdb
go
CREATE TABLE #xp_results (job_id               UNIQUEIDENTIFIER NOT NULL,
			  last_run_date         INT              NOT NULL,
			  last_run_time         INT              NOT NULL,
 			  next_run_date         INT              NOT NULL,
        		  next_run_time         INT              NOT NULL,
			  next_run_schedule_id  INT              NOT NULL,
  			  requested_to_run      INT              NOT NULL, 
			  request_source        INT              NOT NULL,
			  request_source_id     sysname          collate database_default NULL,
			  running               INT              NOT NULL, 
			  current_step          INT              NOT NULL,
 			  current_retry_attempt INT              NOT NULL,
			  job_state             INT              NOT NULL)

/* Capture job execution information (for local jobs only since that''s all SQLServerAgent caches) */

DECLARE @is_sysadmin INT
DECLARE @job_owner SYSNAME
SET @job_owner=SUSER_SNAME()

/* VERIFY ACCOUNT HAS ACCESS TO THIS INFORMATION */

SELECT @is_sysadmin = ISNULL(IS_SRVROLEMEMBER(N''sysadmin''), 0)
IF (@is_sysadmin = 0)	
BEGIN
	SELECT @is_sysadmin = ISNULL(IS_MEMBER(N''SQLAgentReaderRole''), 0)
END

SELECT @job_owner = suser_sname(suser_sid())	

/* GET BASE SQL JOB DATA */

INSERT INTO #xp_results
EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner, NULL

/* check if the job is running.  */

IF (Select count (*) from #xp_results, sysjobs where sysjobs.job_id = #xp_results.job_id AND sysjobs.name like ''DB3-FIN-FIN-mrdb101%'' AND job_state <> 1) > 0
	Begin
		declare @ReportText VarChar(255)
		set @ReportText = ''Replication job DB3-FIN-FIN-mrdb101-9 has stopped. Please investigate.''
		--print @ReportText
		EXEC master..xp_logevent 60000, @ReportText, informational
		select count(*) from Replication_Job_Stopped
	End

/*			0 Returns only those jobs that are not idle or suspended.
			1 Executing.			
			2 Waiting for thread.			
			3 Between retries.			
			4 Idle.			
			5 Suspended.			
			7 Performing completion actions.		
*/
go
drop table #xp_results', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Log Reader Job]    Script Date: 10/06/2011 10:55:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Log Reader Job', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use msdb
go
CREATE TABLE #xp_results (job_id               UNIQUEIDENTIFIER NOT NULL,
			  last_run_date         INT              NOT NULL,
			  last_run_time         INT              NOT NULL,
 			  next_run_date         INT              NOT NULL,
        		  next_run_time         INT              NOT NULL,
			  next_run_schedule_id  INT              NOT NULL,
  			  requested_to_run      INT              NOT NULL, 
			  request_source        INT              NOT NULL,
			  request_source_id     sysname          collate database_default NULL,
			  running               INT              NOT NULL, 
			  current_step          INT              NOT NULL,
 			  current_retry_attempt INT              NOT NULL,
			  job_state             INT              NOT NULL)

/* Capture job execution information (for local jobs only since that''s all SQLServerAgent caches) */

DECLARE @is_sysadmin INT
DECLARE @job_owner SYSNAME
SET @job_owner=SUSER_SNAME()

/* VERIFY ACCOUNT HAS ACCESS TO THIS INFORMATION */

SELECT @is_sysadmin = ISNULL(IS_SRVROLEMEMBER(N''sysadmin''), 0)
IF (@is_sysadmin = 0)	
BEGIN
	SELECT @is_sysadmin = ISNULL(IS_MEMBER(N''SQLAgentReaderRole''), 0)
END

SELECT @job_owner = suser_sname(suser_sid())	

/* GET BASE SQL JOB DATA */

INSERT INTO #xp_results
EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner, NULL

/* check if the job is running.  */

IF (Select count (*) from #xp_results, sysjobs where sysjobs.job_id = #xp_results.job_id AND sysjobs.name = ''DB3-FIN-2'' AND job_state <> 1) > 0
	Begin
		declare @ReportText VarChar(255)
		set @ReportText = ''Replication job DB3-FIN-2 has stopped. Please investigate.''
		--print @ReportText
		EXEC master..xp_logevent 60000, @ReportText, informational
		select count(*) from Replication_Job_Stopped
	End

/*			0 Returns only those jobs that are not idle or suspended.
			1 Executing.			
			2 Waiting for thread.			
			3 Between retries.			
			4 Idle.			
			5 Suspended.			
			7 Performing completion actions.		
*/
go
drop table #xp_results', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 30 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110605, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
		
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


