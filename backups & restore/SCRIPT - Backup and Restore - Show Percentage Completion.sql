--Query to determine percentage of completion for backups:

Select session_id,
db_name(database_id) as 'Database', 
cast(percent_complete as varchar) + '%' as 'percent_complete', 
CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
     + CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
     + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go, 
wait_type, last_wait_type, blocking_session_id
from sys.dm_exec_requests 
where command like 'Backup%' 
or command like  'Restore%'
or command like  'DB STARTUP'
or command like  'DBCC%'





