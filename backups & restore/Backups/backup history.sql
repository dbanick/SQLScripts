

---------------------------------------------------------------------------------
--Database Backups for all databases over past two weeks confirmed for sql2000 
---------------------------------------------------------------------------------
use msdb
SELECT 
  -- CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
   database_name, 
  -- backup_start_date, --comment out this line to only return completion time
   backup_finish_date--,
   --(backup_size * 8 /1024) as size_in_MB
, backupmediafamily.physical_device_name
 from backupset
join backupmediafamily on 
backupset.media_set_id = backupmediafamily.media_set_id
where (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 14)
and type='D' 
--and database_name = 'Cintergy' --uncomment front of line and change name in quotes to specify specific db
order by 
type asc,
database_name asc,
backup_finish_date desc


---------------------------------------------------------------------------------
--Database Backups for all databases over past two weeks SQL2005 + 
---------------------------------------------------------------------------------
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
   msdb.dbo.backupmediafamily.physical_device_name  
 FROM   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 14)--adjust this for # of days
and backupset.type='D' --comment out the AND to return logs too
-- and backupset.database_name = 'Works' --uncomment front of line and change name in quotes to specify specific db
ORDER BY 
   msdb.dbo.backupset.database_name,
   msdb.dbo.backupset.backup_finish_date desc
   






SELECT 
	bs.database_name, 
	bs.backup_start_date, --comment out this line to only return completion time
	bs.backup_finish_date,
    CASE bs.type 
       WHEN 'D' THEN 'Database' 
       WHEN 'L' THEN 'Log' 
   END AS backup_type, 
   (bs.backup_size / 1048576)--* 8 /1024)
 as size_in_MB, 
   bmf.physical_device_name  
 FROM   msdb.dbo.backupmediafamily bmf
   INNER JOIN msdb.dbo.backupset bs
   ON bmf.media_set_id = bs.media_set_id 
WHERE  (CONVERT(datetime, bs.backup_start_date, 102) >= GETDATE() - 14)--adjust this for # of days
and bs.type='D' --comment out the AND to return logs too
and bs.database_name = 'BSS' --uncomment front of line and change name in quotes to specify specific db
and bmf.physical_device_name like '%.bak%'
ORDER BY 
   bs.backup_finish_date desc