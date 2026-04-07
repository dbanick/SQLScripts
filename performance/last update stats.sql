SELECT    s.[Name] as [Schema]
,        t.[name] as [Table]
,        SUM(p.rows) as [RowCount]
,		i.name as [IndexName]
,		STATS_DATE(i.object_id, i.index_id) as [StatsDate]

FROM sys.indexes i 

JOIN sys.objects o
ON i.object_id = o.object_id


JOIN sys.tables t
ON o.object_id = t.object_id

JOIN sys.schemas s
ON t.schema_id = s.schema_id

JOIN sys.partitions p
ON p.object_id = t.object_id

JOIN  sys.allocation_units a
ON  p.partition_id = a.container_id

WHERE    p.index_id  in(0,1) -- 0 heap table , 1 table with clustered index
AND        p.rows is not null
AND        a.type = 1  -- row-data only , not LOB
AND p.rows > 0
AND i.name is not null

GROUP BY s.[Name], t.[name], i.name, i.index_id, i.object_id
ORDER BY 5, 1,2