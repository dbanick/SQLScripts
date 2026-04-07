set nocount on 
DECLARE @dbname varchar(100) 
DECLARE @tablename varchar(100) 
DECLARE @table varchar (100) 

SET @Table = 'IX_AttributeInternal_Name' 

create table #tableName ( 
dbName varchar(100), 
tablename varchar(100)) 

declare dbcursor CURSOR for SELECT name FROM master..sysdatabases 
Open dbcursor 

Fetch next from dbcursor 
into @dbname 

WHILE @@FETCH_STATUS = 0 
BEGIN 

DECLARE @SQL varchar (5000) 

SET @SQL = 'select ''' + cast(@dbname as varchar(500)) + ''', cast(name as varchar)from [' + cast(@dbname as varchar(500)) + ']..sysobjects Where name like ''%' + cast(@table as varchar(500)) + '%'' and xtype = ''U'' '
--print @dbname

--PRINT @SQL 

insert into #tableName 
exec (@SQL) 


Fetch next from dbcursor 
into @dbname 
END 

select * from #tableName 
drop table #tableName 
CLOSE dbcursor 
DEALLOCATE dbcursor

