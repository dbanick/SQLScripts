


-- Script 14
-- List unused indexes
-- now includes column name

SELECT  OBJECT_NAME(i.[object_id]) AS [Table Name] ,
        i.name,
		'column' = c.name,
		'column usage' = CASE ic.is_included_column
		WHEN 0 then 'KEY'
		ELSE 'INCLUDED'
		END
		FROM    sys.indexes AS i
        INNER JOIN sys.objects AS o ON i.[object_id] = o.[object_id]
		INNER JOIN sys.index_columns as ic on i.[object_id] = ic.[object_id] AND i.[index_id] = ic.[index_id]
		INNER JOIN sys.columns as c on c.[object_id] = ic.[object_id]AND ic.[column_id] = c.[column_id]
WHERE   i.index_id NOT IN ( SELECT  s.index_id
                            FROM    sys.dm_db_index_usage_stats AS s
                            WHERE   s.[object_id] = i.[object_id]
                                    AND i.index_id = s.index_id
                                    AND database_id = DB_ID() )
        AND o.[type] = 'U'
ORDER BY OBJECT_NAME(i.[object_id]) ASC ;
