SELECT  OBJECT_NAME(s.[object_id]) AS [ObjectName] ,
        i.name AS [IndexName] , f.name as [filegroup],
        i.index_id ,
        user_seeks + user_scans + user_lookups AS [Reads] ,
        user_updates AS [Writes] ,
        i.type_desc AS [IndexType] ,
        i.fill_factor AS [FillFactor],
        sum ( st.used_page_count ) * 8/1024 as [Entire Table Size MB],
        SUM(user_seeks + user_scans + user_lookups + user_updates) * (sum ( st.used_page_count ) * 8/1024/1024) as [ActivityImpact]
FROM    sys.dm_db_index_usage_stats AS s
        INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
        INNER JOIN sys.dm_db_partition_stats st
		ON i.[object_id] = st.[object_id]
		INNER JOIN sys.filegroups f
		ON i.data_space_id = f.data_space_id
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND i.index_id = s.index_id
        AND s.database_id = DB_ID()
        AND i.index_id <= 1
GROUP BY OBJECT_NAME(s.[object_id]), i.name, f.name, i.index_id, 
        user_seeks + user_scans + user_lookups, user_updates, i.type_desc, i.fill_factor
ORDER BY 9 desc, OBJECT_NAME(s.[object_id]) ,
        writes DESC ,
        reads DESC ;