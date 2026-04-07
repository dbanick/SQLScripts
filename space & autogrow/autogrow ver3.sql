--pull autogrow settings for all files, 
--search results by autogrow enabled, settings, database
--compatible with 2005 and newer
create table #tempAutogrow(
"Database_Name" varchar(60),
"File_Name" varchar(100),
"Current_Size_In_MB" int,
"Autogrow_Setting" varchar(100), 
"Autogrow_Enabled" varchar(20),
"File_Location" varchar(1)
)

--create table for xp_fixeddrives
create table #tempDrives(
"Drive" varchar(3),
"MB_Free" int
)

insert into #tempDrives
exec xp_fixeddrives


insert into #tempAutogrow
exec sp_msforeachdb 
'use [?];
select 

DB_NAME(mas.database_id),

dat.name,
mas.size * 8.0 / 1024,

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
 
select distinct
auto.Database_Name,
auto.File_Name,
convert(varchar, auto.Current_Size_In_MB) + ' MB' as "Current Size",
auto.Autogrow_Setting,
auto.Autogrow_Enabled,
auto.File_Location,
drive.MB_Free
from #tempAutogrow as auto
join #tempDrives as drive
on drive.Drive = auto.File_Location

--where auto.Autogrow_Enabled = 'Disabled' 
--where auto.Database_Name = 'tempdb'

--useful autogrow settings
order by auto.Database_Name, auto.File_Name
--order by auto.Autogrow_Enabled
--order by auto.Autogrow_Setting

drop table #tempAutogrow --cleanup temp table
drop table #tempDrives