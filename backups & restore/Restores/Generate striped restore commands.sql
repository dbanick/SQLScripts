/* to run the full restore automatically FOR SMALLER DB'S WITH ONLY 1 BACKUP FILE  

 

DECLARE @URL NVARCHAR(250) 

Declare @dbname NVARCHAR(250)= 'AGTest_SC' 

SET @URL = ( 

Select TOP 1 f.physical_device_name from [msdb].[dbo].[backupset] s with (nolock),  

[msdb].[dbo].backupmediafamily f with (nolock) 

where s.database_name = @dbname and s.type = 'd' 

and s.backup_finish_date >  DATEADD(DD, -10, GETDATE()) 

and s.media_set_id = f.media_set_id 

order by s.backup_finish_date desc) 

 

 

SELECT @URL 

USE [master] 

RESTORE DATABASE @dbname FROM  URL = @URL WITH  FILE = 1,   

  NOUNLOAD,  NoRecovery, REPLACE,  STATS = 5 

 

 

GO 

--*/

IF Object_id('tempdb.dbo.#cmd') IS NOT NULL
  DROP TABLE #cmd

CREATE TABLE #cmd
  (
     id      INT IDENTITY,
     db      VARCHAR(500),
     command VARCHAR(max)
  )

-- FOR THOSE DATABASES WHICH ARE SRIPED IN TO 4  
IF Object_id('tempdb.dbo.#templog') IS NOT NULL
  DROP TABLE #templog

IF Object_id('tempdb.dbo.#tempfull') IS NOT NULL
  DROP TABLE #tempfull



DECLARE @URL NVARCHAR(250)
DECLARE @dbname NVARCHAR(250)= 'AGTest_SC'
DECLARE @RestoreLogs BIT = 0
DECLARE dbcursor CURSOR FOR
  SELECT NAME
  FROM   master..sysdatabases
  WHERE  NAME NOT IN ( 'master', 'model', 'msdb', 'tempdb' )

OPEN dbcursor

FETCH next FROM dbcursor INTO @dbname

WHILE @@FETCH_STATUS = 0
  BEGIN
  
	  IF Object_id('tempdb.dbo.#tempfull') IS NOT NULL
        DROP TABLE #tempfull


		CREATE TABLE #tempfull
  (
     [id]                 [INT] IDENTITY(1, 1) NOT NULL,
     backup_finish_date   DATETIME,
     physical_device_name NVARCHAR(4000)
  )

      INSERT INTO #tempfull
      SELECT s.backup_finish_date,
             f.physical_device_name
      FROM   [msdb].[dbo].[backupset] s WITH (nolock),
             [msdb].[dbo].backupmediafamily f WITH (nolock)
      WHERE  s.database_name = @dbname
             AND ( s.type = 'd' )
             AND s.backup_finish_date > Dateadd(dd, -10, Getdate())
             AND s.media_set_id = f.media_set_id
      ORDER  BY s.backup_finish_date DESC

      IF Object_id('tempdb.dbo.#templog') IS NOT NULL
        DROP TABLE #templog

      SELECT s.backup_finish_date,
             f.physical_device_name
      INTO   #templog
      FROM   [msdb].[dbo].[backupset] s WITH (nolock),
             [msdb].[dbo].backupmediafamily f WITH (nolock)
      WHERE  s.database_name = @dbname
             AND ( s.type = 'l' )
             AND s.backup_finish_date > Dateadd(dd, -10, Getdate())
             AND s.media_set_id = f.media_set_id
             AND s.backup_finish_date >= (SELECT TOP 1 backup_finish_date
                                          FROM   #tempfull)
      ORDER  BY s.backup_finish_date DESC

      DECLARE @backupfile1 VARCHAR(3000) = (SELECT physical_device_name
         FROM   #tempfull
         WHERE  id = 1)
      DECLARE @backupfile2 VARCHAR(3000) = (SELECT physical_device_name
         FROM   #tempfull
         WHERE  id = 2)
      DECLARE @backupfile3 VARCHAR(3000) = (SELECT physical_device_name
         FROM   #tempfull
         WHERE  id = 3)
      DECLARE @backupfile4 VARCHAR(3000) = (SELECT physical_device_name
         FROM   #tempfull
         WHERE  id = 4)

      INSERT INTO #cmd
      SELECT @dbname,
             'RESTORE DATABASE ' + @dbname
             + '  FROM  URL =  N''' + @backupfile1
             + ''' ,  URL =   N''' + @backupfile2
             + ''' ,  URL =  N''' + @backupfile3
             + ''' ,  URL =   N''' + @backupfile4
             + '''  WITH   NoRecovery, REPLACE,  STATS = 5'

      IF @RestoreLogs = 1
        BEGIN
            INSERT INTO #cmd
            SELECT @dbname,
                   'RESTORE LOG  ' + @dbname + '  FROM  URL = '''
                   + physical_device_name
                   +
        '''  WITH   NOUNLOAD,  NoRecovery, REPLACE,  STATS = 5'
            FROM   #templog
            ORDER  BY backup_finish_date ASC
        END

      FETCH next FROM dbcursor INTO @dbname
  END

CLOSE dbcursor

DEALLOCATE dbcursor

DROP TABLE #templog

SELECT *
FROM   #cmd
WHERE  db NOT LIKE 'soils%'
        OR db = 'Soils20241001'

DROP TABLE #cmd 