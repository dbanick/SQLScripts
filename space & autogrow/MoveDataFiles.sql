/*

Nicks.

use master
go
select 'alter database [' +db_name(dbid) +'] MODIFY FILE (NAME = '+ name +', FILENAME = ''L:\_SQLLogs\'+rtrim(reverse(substring(reverse(fileName),0,patindex('%\%',reverse(fileName)))))+''')'
from sysaltfiles where dbid> 4 --dbid> 4 means not master, model, msdb, tempdb
and groupid =0 -- groupid 0 = logs
--and filename like 'D:\_SQLData%' -- you can set this to a location if you only want to move logs that live on a certain drive already

 


select 'alter database [' +db_name(dbid) +'] SET OFFLINE WITH ROLLBACK IMMEDIATE'
from sysaltfiles where dbid> 4 
and fileid =2 
--and filename like 'D:\_SQLData%'

 

SELECT '********* MOVE THE FILES THEN RUN THE LAST SCRIPT **************'

 

select 'alter database [' +db_name(dbid) +'] SET ONLINE'
from sysaltfiles where dbid> 4 
and fileid =2 
--and filename like 'D:\_SQLData%'

*/

set nocount on
DECLARE @dbname varchar(100)
DECLARE @datalogical varchar(100)
DECLARE @dataphysical varchar(400)
DECLARE @command varchar(4000)
DECLARE @DataPath varchar(300)
DECLARE @LogPath varchar(300)

Set @DataPath = 'D:\Data\'
Set @LogPath = 'L:\Logs\'

create table #filemovecmds (
                dbName varchar(100),
                command varchar(4000))

declare dbcursor CURSOR for SELECT name FROM master..sysdatabases 
where name not in ('master','model','msdb','tempdb')
and DATABASEPROPERTYEX(name, 'Status') != 'OFFLINE'
Open dbcursor

Fetch next from dbcursor
into @dbname

WHILE @@FETCH_STATUS = 0
    BEGIN 
								
		DECLARE @fileAMT int
		SET @fileAMT = (select MAX(fileid) from sysaltfiles where DB_NAME(dbid) = @dbname)
		DECLARE @fileID int
		SET @fileID = 1
                              								
		WHILE @fileID <= @fileAMT
			BEGIN
		
			select @datalogical=rtrim(name), @dataphysical=rtrim(reverse(substring(reverse(fileName),0,patindex('%\%',reverse(fileName))))) 
			FROM sysaltfiles where DB_NAME(dbid) = @dbname and fileid = @fileID

			set @command = 'alter database [' + @dbname +']' + ' MODIFY FILE ( NAME = [' + @datalogical + '], FILENAME = ''' 

			if @fileID = 2
			set @command = @command + @LogPath + '' + @dataphysical + ''');'
			else
			set @command = @command + @DataPath + '' + @dataphysical + ''');'                                                       
			SET @fileID = @fileID + 1
		
			insert #filemovecmds
			VALUES (@dbname, @command)

			END                       								
		Fetch next from dbcursor
		into @dbname
    END

select  *
--dbname, command
from #filemovecmds
order by dbName 
drop table #filemovecmds
CLOSE dbcursor
DEALLOCATE dbcursor
