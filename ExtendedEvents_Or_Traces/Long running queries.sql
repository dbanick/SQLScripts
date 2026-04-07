DROP EVENT SESSION [long_running_queries] ON SERVER
GO
CREATE EVENT SESSION [long_running_queries] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1)
    ACTION(sqlserver.database_name,sqlserver.sql_text,sqlserver.tsql_stack)
    WHERE ([package0].[greater_than_equal_int64]([duration],(2000000)) AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'backup'))),
ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)
    ACTION(sqlserver.database_name,sqlserver.sql_text,sqlserver.tsql_stack)
    WHERE ([package0].[greater_than_equal_uint64]([duration],(2000000)) AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'backup'))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.database_name,sqlserver.sql_text,sqlserver.tsql_stack)
    WHERE ([package0].[greater_than_int64]([duration],(2000000)) AND [package0].[greater_than_uint64]([sqlserver].[database_id],(1)) AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'backup'))) 
ADD TARGET package0.event_file(SET filename=N'C:\RDX\XEventSessions\long_running_queries.xel',max_file_size=(10),max_rollover_files=(50),metadatafile=N'C:\RDX\XEventSessions\long_running_queries.xem')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


