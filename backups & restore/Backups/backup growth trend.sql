--show how much database / backups have grown over time

create table #DB_Backup_Growth
([Database] varchar(256),
[Year] int,
[Month] int,
Backup_Size_MB dec(18,2),
Compressed_Size_MB dec(18,2),
Compression_ratio dec(18,8)
)

insert into #DB_Backup_Growth
SELECT
[database_name] AS "Database",
DATEPART(year,[backup_start_date]) AS "Year",
DATEPART(month,[backup_start_date]) AS "Month",
AVG([backup_size]/1024/1024) AS "Backup Size MB",
AVG([compressed_backup_size]/1024/1024) AS "Compressed Backup Size MB",
AVG([backup_size]/[compressed_backup_size]) AS "Compression Ratio"
FROM msdb.dbo.backupset
WHERE [type] = 'D'
GROUP BY [database_name],DATEPART(yy,[backup_start_date]),DATEPART(mm,[backup_start_date])


select cm.[Database], cm.Backup_Size_MB - lm.Backup_Size_MB as [growth_of_uncompressed_backups_over_last_month], 
cm.Compressed_Size_MB - lm.Compressed_Size_MB as [growth_of_compressed_backups_over_last_month] ,
((cm.Compressed_Size_MB - tm.Compressed_Size_MB)/3) as [avg_growth_over_3_mo],
((cm.Compressed_Size_MB - sm.Compressed_Size_MB)/6) as [avg_growth_over_6_mo]
from #DB_Backup_Growth cm 
left join #DB_Backup_Growth lm on cm.[Database] = lm.[Database]
left join #DB_Backup_Growth tm on tm.[Database] = lm.[Database]
left join #DB_Backup_Growth sm on sm.[Database] = lm.[Database]
where 
cm.[Year] = DATEPART(yy,GETDATE())
and cm.[Month] = DATEPART(mm,GETDATE())
and lm.[Year] = DATEPART(yy, DATEADD(MONTH,-1,GETDATE()))
and lm.[Month] = DATEPART(mm, DATEADD(MONTH,-1,GETDATE()))
and tm.[Year] = DATEPART(yy, DATEADD(MONTH,-3,GETDATE()))
and tm.[Month] = DATEPART(mm, DATEADD(MONTH,-3,GETDATE()))
and sm.[Year] = DATEPART(yy, DATEADD(MONTH,-6,GETDATE()))
and sm.[Month] = DATEPART(mm, DATEADD(MONTH,-6,GETDATE()))

drop table #DB_Backup_Growth