SELECT 
@@SERVERNAME,
DB_NAME(),
 t.NAME AS TableName,
(SUM(a.total_pages) * 8) / 1024 AS TotalSpaceMB,
 p.rows
FROM 
 sys.tables t
INNER JOIN  
 sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
 sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
 sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
t.NAME NOT LIKE 'dt%' AND
t.name in (SELECT DISTINCT TABLE_NAME--, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE DATA_TYPE IN ('FILESTREAM','XML','VARBINARY','TEXT','NTEXT','IMAGE') 
OR(DATA_TYPE IN ('VARCHAR', 'NVARCHAR') AND CHARACTER_MAXIMUM_LENGTH = -1)) AND
i.OBJECT_ID > 255 AND  
i.index_id <= 1
GROUP BY 
 t.NAME, i.object_id, i.index_id, i.name, p.rows
ORDER BY 
 TotalSpaceMB desc, OBJECT_NAME(i.object_id) 


