SELECT DATEPART(YEAR, bs.backup_finish_date) AS 'Year',DATEPART(MONTH, bs.backup_finish_date) AS 'Month', DATEPART(DAY, bs.backup_finish_date) AS 'Day',
bs.database_name,
  SUM(CONVERT (BIGINT, bs.backup_size / 1048576 )) AS [Uncompressed Backup Size (MB)],
  SUM(CONVERT (BIGINT, bs.compressed_backup_size / 1048576 )) AS [Compressed Backup Size (MB)]
FROM msdb.dbo.backupset bs
WHERE DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) > 0 
AND bs.backup_size > 0
AND bs.database_name = 'Navimon'
AND bs.type = 'L' -- Log backups
AND bs.backup_finish_date >= CONVERT(CHAR(8), (SELECT DATEADD (DAY,(-14), GETDATE())), 112)
GROUP BY  DATEPART(YEAR, bs.backup_finish_date),DATEPART(MONTH, bs.backup_finish_date),DATEPART(DAY, bs.backup_finish_date), bs.database_name
order by 'year' desc, 'month' desc, 'day' desc