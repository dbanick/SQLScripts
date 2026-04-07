--check the status of current processes, returning percent complete and minutes remaining if possible

select DB_Name (database_id) as DatabaseName
,blocking_session_id
,session_id
,percent_complete
,minutestocomplete=estimated_completion_time/60000
,command
,text
,start_time
,status
,wait_time
,time_taken=total_elapsed_time/60000
,wait_type
,last_wait_type
,reads
,writes
,logical_reads
from sys.dm_exec_requests
cross apply sys.dm_exec_sql_text (sql_handle)
where session_id > 50
