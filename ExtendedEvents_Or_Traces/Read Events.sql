declare @XELpath varchar(1000) = 'E:\XE_TARGET\SP_EXEC_TRACE*.xel' --set path of file location
declare @sql varchar(2000)

if object_id('tempdb.dbo.#XELtable') is not null
begin
        drop table #XELtable
end

create table #XELtable (xed XML)

set nocount on

set @sql = 'insert into #XELtable select CAST(event_data as XML) from fn_xe_file_target_read_file(''' + @XELpath + ''',NULL,NULL,NULL)'
exec(@sql)

select distinct
        DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), xed.value('(event[1]/@timestamp)[1]','datetime')) as [timestamp],
        xed.value('(event[1]/action[@name="session_id"]/value)[1]','int') as [spid],
        xed.value('(event[1]/action[@name="database_name"]/value)[1]','sysname') as [dbname],
        xed.value('(event[1]/data[@name="object_type"]/text)[1]','varchar(25)') as [object_type],
        xed.value('(event[1]/data[@name="object_name"]/value)[1]','varchar(25)') as [object_name],
        xed.value('(event[1]/action[@name="sql_text"]/value)[1]','varchar(max)') as [sql_text],
        xed.value('(event[1]/data[@name="statement"]/value)[1]','varchar(max)') as [statement],
        xed.value('(event[1]/data[@name="duration"]/value)[1]','bigint')/1000000 as [duration_sec],
        xed.value('(event[1]/data[@name="cpu_time"]/value)[1]','bigint') as [cpu_time],
        xed.value('(event[1]/data[@name="physical_reads"]/value)[1]','bigint') as [physical_reads],
        xed.value('(event[1]/data[@name="logical_reads"]/value)[1]','bigint') as [logical_reads]
from #XELtable
order by [timestamp] desc
