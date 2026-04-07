CREATE EVENT SESSION [TRACE_SP] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1),collect_statement=(0)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.username)
    WHERE ([package0].[equal_uint64]([object_type],(8272)) AND [package0].[equal_uint64]([source_database_id],(7)))) 
ADD TARGET package0.event_file(SET filename=N'C:\rdx\EE\SP_Exec.xel',metadatafile=N'C:\rdx\EE\SP_Exec.xem')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO



CREATE EVENT SESSION [Queries] ON SERVER 
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([package0].[greater_than_uint64]([duration],(100000)))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([package0].[greater_than_uint64]([duration],(100000)))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([package0].[greater_than_int64]([duration],(100000)))) 
ADD TARGET package0.event_file(SET filename=N'C:\rdx\EE\Queries.xel',max_file_size=(256),max_rollover_files=(16))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO


