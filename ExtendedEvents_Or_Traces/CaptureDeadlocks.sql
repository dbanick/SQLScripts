CREATE EVENT SESSION [Deadlocks] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.session_id,sqlserver.sql_text)) 
ADD TARGET package0.event_file(SET filename=N'C:\RDX\DB2\Deadlocks.xel',max_file_size=(25),max_rollover_files=(25))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO


