set nocount on
DECLARE @dbname varchar(100)
DECLARE @tablename varchar(100)
DECLARE @table varchar (100)

SET @Table = 'Contact'

create table #tableName (
	dbName varchar(100),
	tablename varchar(100))

declare dbcursor CURSOR for SELECT name FROM master..sysdatabases
Open dbcursor

Fetch next from dbcursor
into @dbname

WHILE @@FETCH_STATUS = 0
	BEGIN 
	
		DECLARE @SQL varchar (500)
		
		SET @SQL = 'select ''' + @dbname + ''', cast(name as varchar)from ' + @dbname + '..sysobjects Where name like ''%' + @table + '%'' and xtype = ''U'' '
		
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