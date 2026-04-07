SELECT 
   --CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
   msdb.dbo.backupset.database_name, 
  -- msdb.dbo.backupset.backup_start_date, --comment out this line to only return completion time
   msdb.dbo.backupset.backup_finish_date,
    CASE msdb..backupset.type 
       WHEN 'D' THEN 'Database' 
	WHEN 'I' then 'Diff'
       WHEN 'L' THEN 'Log' 
   END AS backup_type, 
   (msdb.dbo.backupset.backup_size / 1048576)--* 8 /1024)
 as size_in_MB, 
 (msdb.dbo.backupset.compressed_backup_size / 1048576)  as compressed_size,
   msdb.dbo.backupmediafamily.physical_device_name  ,
   CASE msdb..backupset.type 
       WHEN 'D'
	   THEN 'restore database ' + msdb.dbo.backupset.database_name + ' from disk = ''F:\' +  msdb.dbo.backupset.name  + '.bak'' with norecovery, replace, stats=10'
	   WHEN 'L' 
	   THEN 'restore log ' + msdb.dbo.backupset.database_name + ' from disk = ''F:\' +  msdb.dbo.backupset.name  + '.trn'' with norecovery, stats=10'

		end as cmd
   --,msdb.dbo.backupset.*
 FROM   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 1)--adjust this for # of days
--and backupset.type='L' --comment out the AND to return logs too
and backupset.database_name = 'windhaven_InsuredPortal' --uncomment front of line and change name in quotes to specify specific db
and backup_finish_date > '2019-09-27 01:02:26.000'
ORDER BY 
   msdb.dbo.backupset.database_name,
   msdb.dbo.backupset.backup_finish_date asc