--This process relies on the built-in "system_health" extended event which should be automatically started with SQL
--This XE is recommended by Microsoft to be running at all times as it has low overhead but tracks valuable information
-- https://msdn.microsoft.com/en-us/library/ff877955(v=sql.110).aspx

--First we want to configure/verify the system_health XE in case it was inadvertantly stopped
--Start the system_health XE if it is not running already
IF NOT EXISTS (select xs.*, xst.* FROM sys.dm_xe_sessions xs
JOIN sys.dm_xe_session_targets xst
ON xs.address = xst.event_session_address
WHERE xs.name = 'system_health'
AND xst.target_name = 'event_file'
)
ALTER EVENT SESSION [system_health] ON SERVER STATE = START
GO

--Configure this session to start with SQL on startup in case not already set
ALTER EVENT SESSION [system_health] ON SERVER WITH (STARTUP_STATE=ON)
GO

--Now we create a SP that takes data from the system_health XE 
--and loads new deadlock information into a permanent table in SystemAdmin database when called
--This will only load the deadlocks that have not been logged already so it can be ran multiple times without issue
USE [SystemAdmin]
---------------------------------------------------------------------------------------------------------------------------
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO 
CREATE PROCEDURE [dbo].[usp_log_deadlocks]
	@retention int = 180
AS
BEGIN
	DECLARE @LastDeadLock DATETIME2, @XE_EVENT_FILE_TARGET XML, @XE_FILE_PATH NVARCHAR(260)
 
	--Determine the file names for the XE session
	SELECT @XE_EVENT_FILE_TARGET = CONVERT(XML, xst.target_data)
	FROM sys.dm_xe_sessions xs
	JOIN sys.dm_xe_session_targets xst
	ON xs.address = xst.event_session_address
	WHERE xs.name = 'system_health'
	AND xst.target_name = 'event_file'
 
	SELECT @XE_FILE_PATH = t.c.value('File[1]/@name', 'varchar(260)') FROM @XE_EVENT_FILE_TARGET.nodes('/EventFileTarget') AS t(c)
 
	-- We want to pull the XML data for the deadlock event
	SELECT CAST(event_data AS XML) AS event_data
	INTO #EE_DEADLOCK_DATA
	FROM sys.fn_xe_file_target_read_file(@XE_FILE_PATH, null, null, null)
	WHERE object_name = 'xml_deadlock_report'


	IF (SELECT OBJECT_ID('DEADLOCK_HISTORY')) IS NULL BEGIN
		CREATE TABLE DEADLOCK_HISTORY
			(
				DeadlockLogID int identity PRIMARY KEY,
				SQLServer NVARCHAR(250) NOT NULL,
				WasEmailed bit NOT NULL,
				DeadlockTimestamp DATETIME2 NULL,
				DeadlockEvent NVARCHAR(250) NULL,
				VictimProcessId NVARCHAR(250) NULL,
				Processid_1 NVARCHAR(250) NULL,
				WaitResource_1 NVARCHAR(250) NULL,
				WaitTime_1 INT NULL,
				OwnerId_1 BIGINT NULL,
				CurrentDb_1 INT NULL,
				LastTranStarted_1 DATETIME2 NULL,
				LastBatchStarted_1 DATETIME2 NULL,
				Statement_1 NVARCHAR(MAX) NULL,
				Client_1 NVARCHAR(250) NULL,
				Hostname_1 NVARCHAR(250) NULL,
				Loginname_1 NVARCHAR(250) NULL,
				Objectname_rid_1 NVARCHAR(250) NULL,
				Objectname_page_1 NVARCHAR(250) NULL,
				Objectname_key_1 NVARCHAR(250) NULL,
				Processid_2 NVARCHAR(250) NOT NULL,
				WaitResource_2 NVARCHAR(250) NULL,
				WaitTime_2 INT NULL,
				OwnerId_2 BIGINT NULL,
				CurrentDb_2 INT NULL,
				LastTranStarted_2 DATETIME2 NULL,
				LastBatchStarted_2 DATETIME2 NULL,
				Statement_2 NVARCHAR(MAX) NULL,
				Client_2 NVARCHAR(250) NULL,
				Hostname_2 NVARCHAR(250) NULL,
				Loginname_2 NVARCHAR(250) NULL,
				Objectname_rid_2 NVARCHAR(250) NULL,
				Objectname_page_2 NVARCHAR(250) NULL,
				Objectname_key_2 NVARCHAR(250) NULL
			)
			
	END
 
	SELECT @LastDeadLock = ISNULL(MAX(LastTranStarted_1), '1900-01-01') FROM DEADLOCK_HISTORY
 
	;WITH CTE_EVENTS AS
		(
			SELECT
				@@SERVERNAME as SQLServer,
				0 as WasEmailed,
				c.value('@timestamp', 'DATETIME2') AS DeadlockTimestamp,
				c.value('(@name)[1]', 'nvarchar(250)') AS DeadlockEvent,
				c.value('(data/value/deadlock/victim-list/victimProcess)[1]/@id', 'nvarchar(250)') AS VictimProcessId,
				c.value('(data/value/deadlock/process-list/process)[1]/@id', 'nvarchar(250)') AS Processid_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@waitresource', 'nvarchar(250)') AS WaitResource_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@waittime', 'int') AS WaitTime_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@ownerId', 'bigint') AS OwnerId_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@currentdb', 'int') AS CurrentDb_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@lasttranstarted', 'datetime2') AS LastTranStarted_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@lastbatchstarted', 'datetime2') AS LastBatchStarted_1,
				c.value('(data/value/deadlock/process-list/process/inputbuf)[1]', 'nvarchar(max)') AS Statement_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@clientapp', 'nvarchar(250)') AS Client_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@hostname', 'nvarchar(250)') AS Hostname_1,
				c.value('(data/value/deadlock/process-list/process)[1]/@loginname', 'nvarchar(250)') AS Loginname_1,
				c.value('(data/value/deadlock/resource-list/ridlock)[1]/@objectname', 'nvarchar(250)') AS objectName_rid_1,
				c.value('(data/value/deadlock/resource-list/pagelock)[1]/@objectname', 'nvarchar(250)') AS objectName_page_1,
				c.value('(data/value/deadlock/resource-list/keylock)[1]/@objectname', 'nvarchar(250)') AS objectName_key_1,
				c.value('(data/value/deadlock/process-list/process)[2]/@id', 'nvarchar(250)') AS Processid_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@waitresource', 'nvarchar(250)') AS WaitResource_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@waittime', 'int') AS WaitTime_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@ownerId', 'bigint') AS OwnerId_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@currentdb', 'int') AS CurrentDb_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@lasttranstarted', 'datetime2') AS LastTranStarted_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@lastbatchstarted', 'datetime2') AS LastBatchStarted_2,
				c.value('(data/value/deadlock/process-list/process/inputbuf)[2]', 'nvarchar(max)') AS Statement_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@clientapp', 'nvarchar(250)') AS Client_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@hostname', 'nvarchar(250)') AS Hostname_2,
				c.value('(data/value/deadlock/process-list/process)[2]/@loginname', 'nvarchar(250)') AS Loginname_2,
				c.value('(data/value/deadlock/resource-list/ridlock)[2]/@objectname', 'nvarchar(250)') AS objectName_rid_2,
				c.value('(data/value/deadlock/resource-list/pagelock)[2]/@objectname', 'nvarchar(250)') AS objectName_page_2,
				c.value('(data/value/deadlock/resource-list/keylock)[2]/@objectname', 'nvarchar(250)') AS objectName_key_2
			FROM #EE_DEADLOCK_DATA
			CROSS APPLY event_data.nodes('//event') AS t (c)
		)
	INSERT DEADLOCK_HISTORY
	SELECT *
	FROM CTE_EVENTS
	WHERE LastTranStarted_1 > @LastDeadLock
	
	DELETE FROM DEADLOCK_HISTORY WHERE DeadlockTimestamp < GETDATE()-@retention 

	DROP TABLE #EE_DEADLOCK_DATA
END

GO

--Create SP that will compile/transform data, and then report off of it
USE [SystemAdmin]
GO

/****** Object:  StoredProcedure [dbo].[usp_report_deadlocks]    Script Date: 9/23/2016 2:51:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_report_deadlocks]
	@EmailAddress varchar(4000) = 'atrepes@baldwinandlyons.com'
AS
BEGIN

	declare @deadlockID int
	declare @subject varchar(250)
	declare DeadlockCursor CURSOR for SELECT DeadlockLogID FROM [SystemAdmin].[dbo].[DEADLOCK_HISTORY] WHERE WasEmailed = 0
	Open DeadlockCursor

	--Create table to hold all deadlock report information if not already existing, 
	--in case there are multiple deadlock entries captured when this is called
	IF OBJECT_ID('SystemAdmin.dbo.DeadlockResults') IS NULL
	BEGIN
		CREATE TABLE DeadlockResults 
		(
			SQLServer NVARCHAR(250) NOT NULL,
			DeadlockLogID INT NOT NULL,
			DeadlockTimestamp DATETIME2 NULL,
			[Database] NVARCHAR(250) NULL,
			Deadlock_Victim NVARCHAR(MAX) NULL,
			Deadlock_Winner NVARCHAR(MAX) NULL,
			Victim_Object NVARCHAR(250) NULL,
			Winner_Object NVARCHAR(250) NULL,
			Victim_Start_Time DATETIME2 NULL,
			Winner_Start_Time DATETIME2 NULL,
			Victim_Login_Name NVARCHAR(250) NULL,
			Winner_Login_Name NVARCHAR(250) NULL
		)
	END

	Fetch next from DeadlockCursor
	into @deadlockID

	WHILE @@FETCH_STATUS = 0
		BEGIN 

		--Check if Processid_1 is the victim; if so select data under that assumption
		--Otherwise, report data back with Processid_2 as victim
		IF ((SELECT Processid_1 from [SystemAdmin].[dbo].[DEADLOCK_HISTORY] where DeadlockLogID = @deadlockID) = (SELECT VictimProcessID from [SystemAdmin].[dbo].[DEADLOCK_HISTORY] where DeadlockLogID = @deadlockID) )
			BEGIN
				INSERT INTO DeadlockResults
				SELECT [SQLServer], DeadlockLogId, [DeadlockTimestamp],
					db_name(currentDB_1) as [database],
					statement_1 as [deadlock_victim],
					statement_2 as [deadlock_winner],
					coalesce(Objectname_rid_1, Objectname_page_1, Objectname_key_1) as [victim_object],
					coalesce(Objectname_rid_2, Objectname_page_2, Objectname_key_2) as [winner_object],
					LastTranStarted_1 as [victim_start_time],
					LastTranStarted_2 as [winner_start_time],
					loginname_1 as [victim_login_name],
					loginname_2 as [winner_login_name]
				FROM [SystemAdmin].[dbo].[DEADLOCK_HISTORY] 
				where DeadlockLogId = @deadlockID
			END
	  ELSE
			BEGIN
				INSERT INTO DeadlockResults
  				SELECT [SQLServer], DeadlockLogId, [DeadlockTimestamp],
					db_name(currentDB_2) as [database],
					statement_2 as [deadlock_victim],
					statement_1 as [deadlock_winner],
					coalesce(Objectname_rid_2, Objectname_page_2, Objectname_key_2) as [victim_object],
					coalesce(Objectname_rid_1, Objectname_page_1, Objectname_key_1) as [winner_object],
					LastTranStarted_2 as [victim_start_time],
					LastTranStarted_1 as [winner_start_time],
					loginname_2 as [victim_login_name],
					loginname_1 as [winner_login_name]
				FROM [SystemAdmin].[dbo].[DEADLOCK_HISTORY] 
				where DeadlockLogId = @deadlockID
			END

	  --Mark this deadlock event as having been reported
	  UPDATE [SystemAdmin].[dbo].[DEADLOCK_HISTORY] set WasEmailed = 1 Where DeadlockLogID = @deadlockID

	  Fetch next from DeadlockCursor
			into @deadlockID
		END
	CLOSE DeadlockCursor
	DEALLOCATE DeadlockCursor

	--Build Subject
	SET @subject = 'Deadlock occurred on ' + @@SERVERNAME

	--Send email
	EXEC msdb.dbo.sp_send_dbmail @recipients=@EmailAddress,
	@subject = @subject,
	@body = 'Deadlock has occurred. View attachment to see the deadlock info',
	@query = 'select * from SystemAdmin.dbo.DeadlockResults',
	@query_result_width = 600,
	@attach_query_result_as_file = 1,
	@query_attachment_filename = 'deadlocks.csv',
	@query_result_separator = ',',
	@query_result_header = 1,
	@query_result_no_padding = 1,
	@exclude_query_output = 1
	
	--Cleanup temp table
	select * from DeadlockResults 
	truncate table DeadlockResults

END
GO

-- Create a job and alert that calls the USP
-- This has no schedule, but will be called by the alert instead
USE [msdb]
GO
DECLARE @jobId_ BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Log_And_Report_Deadlocks', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId_ OUTPUT
select @jobId_

EXEC msdb.dbo.sp_add_jobserver @job_name=N'Log_And_Report_Deadlocks'

EXEC msdb.dbo.sp_add_alert @name=N'Report_Deadlocks', 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=0, 
		@performance_condition=N'Locks|Number of Deadlocks/sec|_Total|>|0', 
		@job_id= @jobId_
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Log_And_Report_Deadlocks', @step_name=N'Log deadlock information to DEADLOCK_HISTORY table', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [SystemAdmin].[dbo].[usp_log_deadlocks]
		--You can pass a retention for how long to keep the rows; default is 180 days
		--Example: exec [SystemAdmin].[dbo].[usp_log_deadlocks] @retention = 60 -- this shortens retention to 60 days', 
		@database_name=N'SystemAdmin', 
		@flags=0
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Log_And_Report_Deadlocks', @step_name=N'Report Deadlock Information', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [SystemAdmin].[dbo].[usp_report_deadlocks]
		--You can pass an email address to this, otherwise it uses the default defined in the SP
		--Example: exec [SystemAdmin].[dbo].[usp_report_deadlocks] @EmailAddress = ''user@baldwinlyons.com'' ', 
		@database_name=N'SystemAdmin', 
		@flags=0
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Log_And_Report_Deadlocks', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_netsend_operator_name=N'', 
		@notify_page_operator_name=N''
GO
