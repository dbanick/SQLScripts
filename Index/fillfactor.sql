create table #rdx_fillfactor (Server varchar (255), DBName varchar(255), TableName varchar(255), IDXName varchar(255), fill_factor tinyint, rows int)

INSERT INTO #rdx_fillfactor
exec sp_MSforeachdb 'use [?];
SELECT @@SERVERNAME as Server, db_name() as DBName, t.name as TableName, idx.name as IDXName, idx.OrigFillFactor as fill_factor, idx.rows as RowsCount
FROM sysindexes idx
INNER JOIN sys.tables t ON idx.id = t.object_id
--WHERE idx.OrigFillFactor < 80 AND idx.OrigFillFactor <> 0'

select * from #rdx_fillfactor
where DBName not in ('master','model','msdb','tempdb','ReportServer','ReportServerTempdb','SSISDB')
drop table #rdx_fillfactor

/*
select spt.tablename, spt.fill_factor, spt.rows,
'ALTER INDEX [' + spt.IDXName + '] ON [DatabaseName].[dbo].[' + spt.TableName + '] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = OFF, FILLFACTOR = ' + cast(100-spt.fill_factor as varchar) + ')'
from #rdx_fillfactor spt
where DBName = 'DatabaseName'
*/