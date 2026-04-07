DECLARE @DB varchar(256) = 'CR_DEV' -- specify database
, @BAKFILE varchar(512)
, @MDF nvarchar(256)
, @MDFFile nvarchar(256)
, @LDF nvarchar(256)
, @LDFFile nvarchar(256)
, @OFFLINESQL varchar (512)
, @RESTORESQL varchar(2048)

set @BAKFILE = (SELECT top 1 bf.physical_device_name
FROM msdb.dbo.backupset AS bs
inner join msdb.dbo.backupmediafamily bf on bf.media_set_id = bs.media_set_id
WHERE bs.type = 'D' 
AND bf.physical_device_name like '%.bak'
AND database_name = @DB
ORDER BY bs.backup_finish_date DESC)

SET @MDF = (select [name] from sysaltfiles where DB_NAME(dbid) = @DB and [fileid] = 1)
SET @MDFFile = (SELECT [filename] from sysaltfiles where DB_NAME(dbid) = @DB and [fileid] = 1)
SET @LDF = (select [name] from sysaltfiles where DB_NAME(dbid) = @DB and [fileid] = 2)
SET @LDFFile = (SELECT [filename] from sysaltfiles where DB_NAME(dbid) = @DB and [fileid] = 2)

--SELECT @MDF, @MDFFILE, @LDF, @LDFFile, @BAKFILE

/* Take the old database offline and restore the new one... */
set @OFFLINESQL = 'ALTER DATABASE [' + @DB + '] SET OFFLINE WITH ROLLBACK IMMEDIATE'
IF EXISTS (SELECT * FROM sys.databases WHERE [name] = @DB and [state] = 0) 
BEGIN
       EXEC  (@OFFLINESQL)
END

-- Restore database
SET @RESTORESQL = 'RESTORE DATABASE [' + @DB + '] FROM DISK = ''' + @BAKFILE + ''' WITH RECOVERY, REPLACE, MOVE ''' + @MDF + ''' TO ''' + @MDFFile + ''', MOVE ''' + @LDF + ''' TO ''' + @LDFFile + ''' '
EXEC  (@RESTORESQL)

