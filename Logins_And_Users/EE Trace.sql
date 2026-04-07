CREATE EVENT SESSION [Connections] ON SERVER 
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.session_nt_username,sqlserver.username)
    WHERE ([error_number]=(18456))),
ADD EVENT sqlserver.login(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.session_nt_username,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'C:\Navisite\EE\Connections.xel',max_file_size=(256),max_rollover_files=(40))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


-----------------------------

--Read Extended Event info into temp table
SELECT convert(XML, event_data) AS Event_Data
INTO #t
FROM sys.fn_xe_file_target_read_file(N'C:\Navisite\EE\Connections*.xel', NULL, NULL, NULL)

/* #t holds data as XML, we want to extract the important details here into individual columns  */
SELECT [Timestamp] = event_data.value(N'(event/@timestamp)[1]', N'datetime')
       ,[client_app_name] = event_data.value(N'(event/action[@name="client_app_name"]/value)[1]', N'nvarchar(100)')
       ,[client_hostname] = event_data.value(N'(event/action[@name="client_hostname"]/value)[1]', N'nvarchar(100)')
       ,[nt_username] = event_data.value(N'(event/action[@name="nt_username"]/value)[1]', N'nvarchar(100)')
       ,[session_nt_username] = event_data.value(N'(event/action[@name="session_nt_username"]/value)[1]', N'nvarchar(100)')
       ,[UserName] = event_data.value(N'(event/action[@name="username"]/value)[1]', N'nvarchar(100)')
       ,[DBName] = event_data.value(N'(event/action[@name="database_name"]/value)[1]', N'nvarchar(100)')
       ,[message] = event_data.value('(event/data[@name="message"])[1]', 'nvarchar(max)')
       ,[clientmachine] = event_data.value('(event/action[@name="client_hostname"])[1]', 'nvarchar(100)')
INTO #t2
FROM #t

--After #t2 is loaded, #t is no longer required
DROP TABLE #t

--for login failures, the username is tracked in the message column, not the username column. This UPDATE corrects that
UPDATE #t2
SET Username = SUBSTRING(message, CHARINDEX('''', message, 1) + 1, CHARINDEX('''', message, CHARINDEX('''', message, 1) + 1) - CHARINDEX('''', message, 1) - 1)
WHERE UserName IS NULL

--Correct the UTC Date to local date
UPDATE #t2
SET [Timestamp] = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), #t2.TIMESTAMP)

SELECT *
FROM #t2
ORDER BY [Timestamp]

DROP TABLE #t2
