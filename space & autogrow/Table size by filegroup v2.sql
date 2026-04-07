/* Get Details of Object on different filegroup
Finding User Created Tables*/
SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name],
 sum ( st.used_page_count ) * 8 as [Entire Table Size KB]
 --sum ( st.used_page_count ) * 8/1024 as [Entire Table Size MB]
FROM sys.indexes i
INNER JOIN sys.filegroups f
ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o
ON i.[object_id] = o.[object_id]
INNER JOIN sys.dm_db_partition_stats st
ON i.[object_id] = st.[object_id]
WHERE i.data_space_id = f.data_space_id
AND o.type = 'U' -- User Created Tables
GROUP BY o.[name], o.type, i.name, i.index_id, f.name
order by 5, 6 desc, 1
GO 
