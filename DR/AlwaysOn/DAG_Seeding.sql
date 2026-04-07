

--select * from sys.dm_hadr_automatic_seeding where start_time > getdate()-3

select ((transferred_size_bytes * 1.000000)/ (database_size_bytes * 1.000000))*100.00000 as percentDone, * from sys.dm_hadr_physical_seeding_stats 


SELECT  
    d.name AS database_name,
    ar.replica_server_name,
    ag.name AS ag_name,
    has.current_state,
    has.start_time,
    has.failure_state_desc,
    has.error_code
FROM sys.dm_hadr_automatic_seeding AS has
JOIN sys.availability_groups AS ag
    ON has.ag_id = ag.group_id
JOIN sys.availability_databases_cluster AS adc
    ON has.ag_db_id = adc.group_database_id
JOIN sys.databases AS d
    ON adc.database_name = d.name
JOIN sys.availability_replicas AS ar
    ON has.ag_id = ar.group_id
   AND has.ag_remote_replica_id = ar.replica_id
   where has.start_time > getdate()-14
ORDER BY has.start_time DESC;


USE master
GO

;WITH CTE
AS
(
SELECT
	ag.[name] AS AGName,
	ar.replica_server_name AS [Underlying AG],
	ag.is_distributed,
	dbs.[name] AS [Database],
	ars.role_desc AS [Role],
	drs.synchronization_health_desc AS [Sync Status],
	drs.log_send_queue_size,
	drs.log_send_rate,
	drs.redo_queue_size,
	drs.redo_rate,
	last_commit_time
FROM sys.databases AS dbs
INNER JOIN sys.dm_hadr_database_replica_states AS drs
ON dbs.database_id = drs.database_id
INNER JOIN sys.availability_groups AS ag
ON drs.group_id = ag.group_id
INNER JOIN sys.dm_hadr_availability_replica_states AS ars
ON ars.replica_id = drs.replica_id
INNER JOIN sys.availability_replicas AS ar
ON ar.replica_id = ars.replica_id
)
SELECT Pri.AGName, Pri.[Database]
, Pri.[Underlying AG] AS [Primary], Sec.[Underlying AG] AS [Seondary]
, [lag in seconds] = DATEDIFF(SECOND, sec.last_commit_time, pri.last_commit_time)
, Pri.[Sync Status] AS PrimaryHealth
, Sec.[Sync Status] AS SecondaryHealth
, Sec.log_send_queue_size, Sec.Redo_Queue_Size
, Sec.log_send_rate, Sec.redo_rate
FROM CTE AS Pri
INNER JOIN CTE AS Sec
ON Pri.[Database] = Sec.[Database]
WHERE 1=1
AND Pri.[Underlying AG] = @@SERVERNAME
AND Sec.[Underlying AG] != @@SERVERNAME
ORDER BY Pri.[Database], Sec.[Underlying AG]
--FOR JSON AUTO;






/*


ALTER AVAILABILITY GROUP [prod-sql-ag02]   
MODIFY   
AVAILABILITY GROUP ON  
 
's7-sql-ag02' WITH (
    SEEDING_MODE = AUTOMATIC  
),
'va-sql-ag02' WITH (
      
    SEEDING_MODE = AUTOMATIC  
);    
GO

*/