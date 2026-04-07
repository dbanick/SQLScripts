--pull autogrow settings for all files, 
--search results by autogrow enabled, settings, database
--compatible with 2005 and newer
create table #tempAutogrow(
"Database" varchar(60),
"File Name" varchar(100),
"Autogrow Setting" varchar(100), 
"Autogrow Enabled" varchar(20),
"File Location" varchar(1)
)

insert into #tempAutogrow
exec sp_msforeachdb 
'use [?];
select 

DB_NAME(mas.database_id),

dat.name,

CASE
WHEN dat.is_percent_growth = 0
THEN LTRIM(STR(dat.growth * 8.0 / 1024,10,1)) + '' MB, ''
ELSE
''By '' + CAST(dat.growth AS VARCHAR) + '' percent, ''
END +
CASE
WHEN dat.max_size = -1 THEN ''unrestricted growth''
ELSE ''restricted growth to '' +
LTRIM(STR(dat.max_size * 8.0 / 1024,10,1)) + '' MB''
END, 

case 
when dat.growth = ''0'' 
Then ''Disabled'' 
Else ''Enabled'' 
End,

LEFT(mas.physical_name, 1)

from sys.database_files as dat
join sys.master_files as mas
on (dat.name = mas.name COLLATE SQL_Latin1_General_CP1_CI_AS)
'
 
select * from #tempAutogrow 
--where autoGrow = 'Disabled' 
--where Database = 'tempdb'

--useful autogrow settings
order by [Database], [File Name]
--order by [Autogrow Enabled]
--order by [Autogrow Setting]

drop table #tempAutogrow --cleanup temp table


