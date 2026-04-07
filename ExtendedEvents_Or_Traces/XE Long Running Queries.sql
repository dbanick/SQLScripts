--this will shred an XE that is designed to pick up long running queries,named Long_Running*
SELECT 
    event.value('(event/@name)[1]', 'varchar(50)') AS event_name, 
    DATEADD(hh, 
            DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), 
            event.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp], 
		event.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(max)') as [database_name],
		event.value('(event/action[@name="username"]/value)[1]', 'nvarchar(max)') as [username],
		event.value('(event/data[@name="duration"]/value)[1]', 'bigint') as [duration],
		event.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint') as [cpu_time],
		event.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') as [logical_reads],
    ISNULL(event.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)'), 
            event.value('(event/data[@name="batch_text"]/value)[1]', 'nvarchar(max)')) AS [stmt/btch_txt], 
    event.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') as [sql_text] 
FROM 
(  
        SELECT CAST(event_data AS XML) AS [event] 
       FROM sys.fn_xe_file_target_read_file
('D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\Long_Running*.xel',
null,
NULL, NULL) 
    ) xd
where event.value ('(event/@timestamp)[1]', 'datetime2')  > '2018-07-30 00:15:55.5303319'
    --ORDER BY 2 DESC;
  

