-- needs more testing on SQL 2000
--to be ran on source server
--requires all backups to be named as <dbname>.bak and in one folder
--This will loop through for each file in the database 
--currently requires all data and log files to be in same drive and folder on destination
--temp table can be queried to only return databases needed
--this will output commands only



set nocount on
DECLARE @dbname varchar(100)
DECLARE @datalogical varchar(100)
DECLARE @data varchar(400)
DECLARE @command varchar(4000)
DECLARE @RestoreDataPath varchar(300)
DECLARE @RestoreLogPath varchar(300)
DECLARE @backupLocation varchar(300)

Set @RestoreDataPath = 'D:\Program Files (x86)\Microsoft SQL Server\MSSQL.1\MSSQL\Data\'
Set @RestoreLogPath = 'D:\Program Files (x86)\Microsoft SQL Server\MSSQL.1\MSSQL\Data\'
Set @backupLocation = 'E:\Migration\A\'



create table #restoreInfo (
                dbName varchar(100),
                command varchar(4000))

declare dbcursor CURSOR for SELECT name FROM master..sysdatabases where name not in ('tempdb', 'master', 'model', 'msdb')
Open dbcursor

Fetch next from dbcursor
into @dbname

WHILE @@FETCH_STATUS = 0
                BEGIN 
								
								DECLARE @fileAMT int
								SET @fileAMT = (select MAX(fileid) from sysaltfiles where DB_NAME(dbid) = @dbname)
								DECLARE @fileID int
								SET @fileID = 1
                                
                                set @command = 'restore database [' + @dbname +']'
                                set @command = @command +' from disk=''' + @backupLocation  + @dbname + '.bak'' with recovery, replace, stats=10' 
                                
                                								
								WHILE @fileID <= @fileAMT
								BEGIN
								
                                USE master
                                select @datalogical=rtrim(name), @data=rtrim(reverse(substring(reverse(fileName),0,patindex('%\%',reverse(fileName))))) FROM sysaltfiles where DB_NAME(dbid) = @dbname and fileid = @fileID
                                
                                --select @datalogical,@data,@loglogical,@log,@RestoreDataPath+@data,@RestoreLogPath+@log

		
                                set @command = @command + ', MOVE ''' + @datalogical + ''' to '''+@RestoreDataPath+@data + ''''
                                                            

                                SET @fileID = @fileID + 1
								END
								
								set @command = @command + ' GO '
                                
                                insert #restoreInfo
                                VALUES (@dbname, @command)
                                								
                                Fetch next from dbcursor
                                into @dbname
                END

select  *
--dbname, command
from #restoreInfo
order by dbName 
drop table #restoreInfo
CLOSE dbcursor
DEALLOCATE dbcursor
