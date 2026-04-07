/* Recent full backup details */
CREATE TABLE #rdxresults
	(
		[Server Name] VARCHAR(255),
		[Database Name] VARCHAR(255),
		[Physical Name] VARCHAR (2500),
		[Uncompressed Backup Size (MB)] BIGINT,
		[Compressed Backup Size (MB)] BIGINT,
		[Compression Ratio] NUMERIC(20,2),
		[Backup Elapsed Time (sec)] INT,
		[Backup Finish Date] DATETIME,
		[Collection Time] DATETIME
	);
INSERT INTO #rdxresults
EXEC sp_MSforeachdb @command1 = 'USE [?];
SELECT bs.server_name AS [Server Name], bs.database_name AS [Database Name], bf.physical_device_name as [Physical Name],
CONVERT (BIGINT, bs.backup_size / 1048576 ) AS [Uncompressed Backup Size (MB)],
CONVERT (BIGINT, bs.compressed_backup_size / 1048576 ) AS [Compressed Backup Size (MB)],
CONVERT (NUMERIC (20,2), (CONVERT (FLOAT, bs.backup_size) /
CONVERT (FLOAT, bs.compressed_backup_size))) AS [Compression Ratio], 
DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) AS [Backup Elapsed Time (sec)],
bs.backup_finish_date AS [Backup Finish Date],
CURRENT_TIMESTAMP AS [Collection Time]
FROM msdb.dbo.backupset AS bs WITH (NOLOCK)
inner join msdb.dbo.backupmediafamily bf on bf.media_set_id = bs.media_set_id
WHERE DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) > 0 
AND bs.backup_size > 0
AND bs.type = ''D'' -- Change to L if you want Log backups
AND database_name = DB_NAME(DB_ID())
AND bs.backup_finish_date >= CONVERT(CHAR(8), (SELECT DATEADD (DAY,(-14), GETDATE())), 112)
ORDER BY bs.database_name, bs.backup_finish_date DESC OPTION (RECOMPILE);';
SELECT * FROM #rdxresults ORDER BY [Database Name] ASC, [Backup Finish Date] ASC;
DROP TABLE #rdxresults;