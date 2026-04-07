;
WITH agg AS
(
    SELECT
        [object_id],
        index_id,
        last_user_seek,
        last_user_scan,
        last_user_lookup,
        last_user_update
    FROM
        sys.dm_db_index_usage_stats
    WHERE
        database_id = DB_ID()
        and index_id in (0,1)
)
SELECT
    ds.[name] AS FG,
    df.name as filename,
    OBJECT_NAME(p.object_id) AS tbl,
    coalesce(i.name, 'HEAP') as idx,
    i.index_id,
    SUM(au.total_pages) / 128.0 AS UsedMB,
    df.size / 128 AS FileSizeMB,
    100.0 * SUM(au.total_pages) / df.size AS PercentUsed,
    last_read = MAX(x.last_read),
    last_write = MAX(x.last_write)
FROM
    sys.database_files df
    JOIN
    sys.data_spaces ds ON df.data_space_id = ds.data_space_id 
    JOIN
    sys.allocation_units au ON ds.data_space_id = au.data_space_id 
    JOIN 
    sys.partitions p ON au.container_id = p.partition_id
    join sys.indexes i on p.object_id = i.object_id and p.index_id = i.index_id
	join (
		SELECT [object_id], index_id, coalesce(last_user_seek,last_user_scan, last_user_lookup) as last_read, last_user_update as last_write FROM agg
	) AS x  on x.object_id = p.object_id and x.index_id = p.index_id
WHERE
    OBJECTPROPERTYEX(p.object_id, 'IsMSShipped') = 0
    and ds.name = 'PRIMARY'
    and df.name = 'Product_Distribution_Engine_Data'
    and au.total_pages > 0
    and p.index_id in (0,1)
 and OBJECT_NAME(p.object_id) in  (SELECT distinct T.TABLE_NAME 
			FROM INFORMATION_SCHEMA.COLUMNS C
				INNER JOIN INFORMATION_SCHEMA.TABLES T
					ON C.TABLE_SCHEMA = T.TABLE_SCHEMA
					AND C.TABLE_NAME = T.TABLE_NAME
			WHERE T.TABLE_TYPE = 'BASE TABLE' 
			AND ((C.DATA_TYPE IN ('VARCHAR', 'NVARCHAR') AND C.CHARACTER_MAXIMUM_LENGTH = -1)
			OR DATA_TYPE IN ('TEXT', 'NTEXT', 'IMAGE', 'VARBINARY', 'XML', 'FILESTREAM'))
			AND T.TABLE_SCHEMA NOT IN('CDC') -- EXCEPTION LIST
	)
GROUP BY     ds.[name], df.name, OBJECT_NAME(p.object_id), coalesce(i.name, 'HEAP'), i.index_id, df.size