--requires mail to be configured.  Must adjust the email @recipients and the category of job if db@maint not configured.  
--Suggest setting to uncategorized until testing is completed
--anything over 1900 results tends to fail due to mail limit (10MB)
--added filters to Consumer and Producer to reduce result amount and added a top 1500 statement
--requires DBCC TRACEON (3605,1204,1222,-1)  to be running

USE [msdb]
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'db@maint' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'db@maint'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N'Deadlock Job', 
 @enabled=1, 
 @notify_level_eventlog=0, 
 @notify_level_email=0, 
 @notify_level_netsend=0, 
 @notify_level_page=0, 
 @delete_level=0, 
 @description=N'Monitors Deadlocks and Emails Deadlock Info', 
 @category_name=N'db@maint', 
@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Deadlock has occurred.', 
 @step_id=1, 
 @cmdexec_success_code=0, 
 @on_success_action=1, 
 @on_success_step_id=0, 
 @on_fail_action=2, 
 @on_fail_step_id=0, 
 @retry_attempts=0, 
 @retry_interval=0, 
 @os_run_priority=0, @subsystem=N'TSQL', 
 @command=N'--== This is for SQL 2005 and higher. ==--
--== We will create a temporary table to hold the error log detail. ==--
--== Before we create the temporary table, we make sure it does not already exist. ==--
 IF OBJECT_ID(''tempdb.dbo.ErrorLog'') IS Not Null
 BEGIN
 DROP TABLE tempdb.dbo.ErrorLog
 END
 --== We have checked for the existence of the temporary table and dropped it if it was there. ==--
 --== Now, we can create the table called tempdb.dbo.ErrorLog ==--
CREATE TABLE tempdb.dbo.ErrorLog (Id int IDENTITY (1, 1) NOT NULL, 
logdate DATETIME, procInfo VARCHAR(10), ERRORLOG VARCHAR(MAX))
--== We create a 3 column table to hold the contents of the SQL Server Error log. ==--
--== Then we insert the actual data from the Error log into our newly created table. ==--
 INSERT INTO tempdb.dbo.ErrorLog
 EXEC master.dbo.sp_readerrorlog
--== With our table created and populated, we can now use the info inside of it. ==--
 BEGIN
--== Set a variable to get our instance name. ==--
--== We do this so the email we receive makes more sense. ==--
 declare @servername nvarchar(150)
 set @servername = @@servername
--== We set another variable to create a subject line for the email. ==-- 
 declare @mysubject nvarchar(200)
 set @mysubject = ''Deadlock event notification on server ''+@servername+''.''
 --== Now we will prepare and send the email. Change the email address to suite your environment. ==-- 

--BE SURE TO SET EMAIL ADDRESS HERE
 EXEC msdb.dbo.sp_send_dbmail @recipients=''wo_sql@hearst.com'',
 @subject = @mysubject,
 @body = ''Deadlock has occurred. View attachment to see the deadlock info'',
 @query = ''
select logdate, procInfo, ERRORLOG from tempdb.dbo.ErrorLog 
where Id >= (select TOP 1 Id from tempdb.dbo.ErrorLog WHERE ERRORLOG Like ''''%Deadlock encountered%'''' order by Id DESC)
AND ERRORLOG not like ''''Database backed%''''
AND ERRORLOG not like ''''Log was backed%''''
AND ERRORLOG not like ''''%db@maint%''''
AND ERRORLOG not like ''''Consumer:%''''
AND ERRORLOG not like ''''Producer:%''''
'',
 @query_result_width = 600,
 @attach_query_result_as_file = 1
 END

 --== Clean up our process by dropping our temporary table. ==--
 DROP TABLE tempdb.dbo.ErrorLog
', 
 @database_name=N'master', 
 @flags=0
SELECT @jobID
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'

--Create alert to start the Deadlock Job
EXEC msdb.dbo.sp_add_alert @name=N'Deadlock Alert', 
		@enabled=1, 
		@delay_between_responses=15, 
		@include_event_description_in=0, 
		@performance_condition=N'SQLServer:Locks|Number of Deadlocks/sec|_Total|>|0', 
		@job_id=@jobid

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
 IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO