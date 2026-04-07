SELECT 'Table Name' = o.name,'Index Name' = b.name, 'Statistics Date' = STATS_DATE(b.object_id, b.index_id)
,a.Index_type_desc
,a.page_count
,a.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (db_id(), null, NULL, NULL, 'DETAILED') as a
JOIN sys.objects o on o.object_id=a.object_id
JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id
where a.avg_fragmentation_in_percent > 20 and a.page_count > 500 and a.index_id <> 0
order by 1,2
GO