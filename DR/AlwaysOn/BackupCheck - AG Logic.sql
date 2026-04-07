/* Database Backups */
SELECT @@SERVERNAME AS [Server Name]
	,s.name AS [Database Name]
	,ag.name AS AvailabilityGroupName
	,(
		SELECT role_desc
		FROM master.sys.dm_hadr_availability_replica_states AS ARS
		WHERE ARS.replica_id = s.replica_id
		) AS 'AlwaysOnRole'
	,ag.automated_backup_preference_desc AS [AGBackupPreference]
	,CAST(b.backup_start_date AS CHAR(11)) AS [Backup Date]
	,CASE 
		WHEN b.backup_start_date > DATEADD(dd, - 1, CURRENT_TIMESTAMP)
			THEN 'Backup is current within a day'
		WHEN b.backup_start_date > DATEADD(dd, - 7, CURRENT_TIMESTAMP)
			THEN 'Backup is current within a week'
		ELSE '*****CHECK BACKUP!!!*****'
		END AS [Comment]
	,CURRENT_TIMESTAMP AS [Collection Time]
FROM master.sys.databases s
LEFT OUTER JOIN msdb..backupset b ON s.name = b.database_name
	AND b.backup_start_date = (
		SELECT MAX(backup_start_date)
		FROM msdb..backupset
		WHERE database_name = b.database_name
			AND type = 'D'
		)
LEFT JOIN sys.availability_databases_cluster adc ON s.group_database_id = adc.group_database_id
LEFT JOIN sys.availability_groups ag ON adc.group_id = ag.group_id
WHERE s.name <> 'tempdb'
ORDER BY s.name
OPTION (RECOMPILE);