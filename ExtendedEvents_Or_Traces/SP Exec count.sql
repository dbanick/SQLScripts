declare @XELpath varchar(1000) = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\SP_Exec*.xel' --set path of file location
declare @sql varchar(2000)

if object_id('tempdb.dbo.#XELtable') is not null
begin
        drop table #XELtable
end

create table #XELtable (xed XML)

set nocount on

set @sql = 'insert into #XELtable select CAST(event_data as XML) from fn_xe_file_target_read_file(''' + @XELpath + ''',NULL,NULL,NULL)'
exec(@sql)


SELECT t.Day, T.hour, T.dbname, T.object_name, count(*)
FROM (
select 
DATEPART(DAY, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), xed.value('(event[1]/@timestamp)[1]','datetime'))) AS 'Day',
DATEPART(Hour, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), xed.value('(event[1]/@timestamp)[1]','datetime'))) as 'hour', 
xed.value('(event[1]/action[@name="database_name"]/value)[1]','sysname') as 'dbname',
xed.value('(event[1]/data[@name="object_name"]/value)[1]','varchar(25)') as [object_name]
from #XELtable
) AS T
GROUP BY T.Day, T.Hour, T.dbname, T.object_name