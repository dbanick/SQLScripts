USE master
GO
SELECT UseCounts,RefCounts, Cacheobjtype, Objtype, 
ISNULL(DB_NAME(dbid),'ResourceDB') AS DatabaseName, TEXT AS SQL 
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
ORDER BY dbid,usecounts DESC;
GO