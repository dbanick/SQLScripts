SELECT
gs.primary_replica as 'Primary Server',
db_name(dd.database_id) as 'Database Name',
secondary_recovery_health_desc as 'Secondary Server Health Status',
synchronization_state_desc as 'Synchronization State',
database_state_desc as 'Database State',
suspend_reason_desc as 'Suspended Reason',
last_sent_time as 'Last Data Send Time',
last_received_time as 'Last Data Received TIme',
last_hardened_time as 'Last Hardened Time',
last_redone_time as 'Last Redone Time',
log_send_queue_size as 'Log Send Queue Size',
log_send_rate as 'Log Send Rate',
redo_queue_size as 'Redo Queue Size',
redo_rate as 'Rate of Redo',
filestream_send_rate as 'Filestream Send Rate',
last_commit_time as 'Last Commit Time',
low_water_mark_for_ghosts as 'Low Water Mark for Ghosts'
FROM sys.dm_hadr_availability_group_states as gs
JOIN sys.dm_hadr_database_replica_states as dd ON gs.group_id = dd.group_id
ORDER BY gs.primary_replica DESC
