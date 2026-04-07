--database
DECLARE @DBPath nvarchar(512)
DECLARE @DBWildcard nvarchar(256)
DECLARE @DBName nvarchar(256)
DECLARE @MDFFile nvarchar(256)
DECLARE @LDFFile nvarchar(256)


SET @DBPath = '\\volume\share\'
SET @DBWildcard = 'database_backup_%.bak'

SET @MDFFile = 'D:\DATA\database.mdf'
SET @LDFFile = 'L:\Logs\database_log.ldf'


/* Get the name of the last full backup*/
CREATE TABLE #database_backups
(
	FILENAME nvarchar(256),
	DEPTH int,
	FILEFLAG int
)

INSERT INTO #database_backups 
	EXEC master..xp_dirtree @DBPath, 1, 1

SELECT TOP 1
       @DBName = RTRIM(filename)
  FROM #database_backups 
 WHERE filename IS NOT NULL
   AND fileflag = 1
   AND filename LIKE @DBWildcard   
 ORDER BY filename DESC

DROP TABLE #database_backups

IF (@DBName IS NULL) or (@DBName = 'File not Found') BEGIN
	RAISERROR('Database backup file not found: %s', 16, 1, @DBWILDCARD)
	RETURN
END

DECLARE @sql varchar(2048)

/* Take the old database offline and restore the new one... */

IF EXISTS (SELECT * FROM sys.databases WHERE [name] = 'database' and [state] = 0) 
BEGIN
	ALTER DATABASE [database] SET OFFLINE WITH ROLLBACK IMMEDIATE
END

-- Restore database
SET @SQL = 'RESTORE DATABASE [database] FROM DISK = ''' + @DBPath + @DBName + ''' WITH RECOVERY, REPLACE, MOVE ''datafile'' TO ''' + @MDFFile + ''', MOVE ''logfile'' TO ''' + @LDFFile + ''' '
EXEC (@SQL)