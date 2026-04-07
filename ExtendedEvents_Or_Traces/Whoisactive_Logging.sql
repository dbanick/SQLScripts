SET NOCOUNT ON; 
 
DECLARE @retention INT = 7 
	,@destination_table VARCHAR(500) = 'WhoIsActiveLogging' 
	,@destination_database SYSNAME = 'master' 
	,@jobName NVARCHAR(500) = '_DBA_whoisactive'
	,@server NVARCHAR(500) = @@servername
	,@schema VARCHAR(MAX) 
	,@SQL NVARCHAR(4000) 
	,@jobSQL NVARCHAR(4000)
	,@jobDesc NVARCHAR(500)
	,@parameters NVARCHAR(500) 
	,@exists BIT; 
 
SET @destination_table = @destination_database + '.dbo.' + @destination_table; 
 
DECLARE @s VARCHAR(MAX)

--cleanup the logging table if already exists
IF OBJECT_ID(@destination_table) IS NOT NULL
	BEGIN
		SET @SQL = 'drop table ' + @destination_table
		exec(@SQL)
		select(@SQL)
	END

--create the logging table
IF OBJECT_ID(@destination_table) IS NULL
    BEGIN;
        EXEC sp_WhoIsActive
			@get_transaction_info = 1,  
			@get_plans = 1 ,
			@find_block_leaders = 1,
			@get_outer_command = 1,
			@return_schema = 1,
			@schema = @s OUTPUT

		SET @s = REPLACE(@s, '<table_name>', @destination_table)
		exec(@s)
		select(@s)
    END

--create index on collection_time
SET @SQL
    = 'USE ' + QUOTENAME(@destination_database)
      + '; IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(@destination_table) AND name = N''cx_collection_time'') SET @exists = 0';
SET @parameters = N'@destination_table varchar(500), @exists bit OUTPUT';
EXEC sys.sp_executesql @SQL, @parameters, @destination_table = @destination_table, @exists = @exists OUTPUT;
 
IF @exists = 0
    BEGIN;
        SET @SQL = 'CREATE CLUSTERED INDEX cx_collection_time ON ' + @destination_table + '(collection_time ASC)';
        EXEC ( @SQL );
    END;

SELECT @jobSQL = '
--collect activity into logging table 
EXEC dbo.sp_WhoIsActive 
	@get_transaction_info = 1,  
	@get_plans = 1 ,
	@find_block_leaders = 1,
	@get_outer_command = 1,
	@destination_table = ''' + @destination_table + '''; 

--purge older data 
DELETE FROM ' + @destination_table + ' WHERE collection_time < DATEADD(day, -'+cast(@retention as nvarchar(10)) +', GETDATE());'
--SELECT @jobSQL

--DROP JOB IF EXISTS
DECLARE @jobIdDrop binary(16)

SELECT @jobIdDrop = job_id FROM msdb.dbo.sysjobs WHERE (name = @jobName)
IF (@jobIdDrop IS NOT NULL)
BEGIN
    EXEC msdb.dbo.sp_delete_job @jobIdDrop
END


-- Create Job
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'_DBA_whoisactive', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=@jobDesc, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId

EXEC msdb.dbo.sp_add_jobserver @job_name=N'_DBA_whoisactive', @server_name = @server

EXEC msdb.dbo.sp_add_jobstep @job_name=N'_DBA_whoisactive', @step_name=N'spwhoisactive Logging', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, 
		@subsystem=N'TSQL', 
		@command=@jobSQL, 
		@database_name=@destination_database, 
		@flags=0

EXEC msdb.dbo.sp_update_job @job_name=N'_DBA_whoisactive', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=@jobDesc,
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_DBA_whoisactive', @name=N'Every minute whoisactive', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20250402, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id

