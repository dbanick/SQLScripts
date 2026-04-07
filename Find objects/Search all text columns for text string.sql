--script is for 2005+ but can be modified for 2000 (sysobjects instead of sys.objects)
--this returns all columns/tables that have a specified text value 'searchString'

DECLARE @searchString varchar(255)
SET @searchString = '%http://hsl2.cboss-staged.com%'

create table #col
(ID int IDENTITY,
sch varchar(255),
tbl varchar(255),
col varchar(255),
xtype int,
txtype varchar(10)
)

Create table #result
(ID int IDENTITY,
sch varchar(255),
tbl varchar(255),
col varchar(255),
cnt varchar(255)
)

insert into #col
--grab schema, table, column, column data type, table type
select s.name, object_name(c.id) as tbl, c.name, c.xtype, o.type from syscolumns c
join sys.objects o on c.id = o.object_id
join sys.schemas s ON o.schema_id = s.schema_id
where c.xtype in (
35, --text
99, --ntext
167, --varchar
231, --nvarchar
239, --nchar
241 --xml
)
and o.type = 'U' --all user tables

--set the while loop sentinals to start at lowest ID and run to highest ID
DECLARE @count int 
SET @count = (SELECT MIN(id) from #col)
DECLARE @Maxcount int 
SET @Maxcount = (select MAX(id) from #col)

--loop will grab count matching search string for all columns that it could be in
while @count <= @Maxcount 
	BEGIN
		
		--set the SQL statement for each column
		DECLARE @sql varchar(255)
		SELECT @sql = 
		'SELECT ''' + (select sch from #col where ID = @count) 
		+ ''', ''' + (select tbl from #col where ID = @count) 
		+ ''', ''' + (select col from #col where ID = @count) 
		+ ''',  count(*) FROM ' + (select sch from #col where ID = @count) 
		+ '.' + (select tbl from #col where ID = @count) 
		+ ' WHERE ' + (select col from #col where ID = @count)
		 + ' like ''' + @searchString + ''' '
		--print @sql

		--insert row count into reporting table
		INSERT INTO #result
		exec (@sql)

		--add to sentinel
		SET @count = @count + 1
	END

--grab all columns that match the search string
SELECT * from #result where cnt > 0

--cleanup
GO
drop table #col
GO
drop table #result
GO