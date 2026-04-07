-- check instance collation
SELECT convert(sysname, serverproperty(N'collation')) AS [Collation]

-- check current database collation
SELECT name, collation_name FROM sys.databases WHERE database_id = DB_ID()

-- check for table columns that do not match current database collation
SELECT DB_Name() as DatabaseName, SCHEMA_NAME(o.schema_id) as SchemaName, o.name as TableName, c.name as ColumnName, c.collation_name 
FROM sys.objects o
INNER JOIN sys.columns c on o.object_id = c.object_id
WHERE o.is_ms_shipped = 0
AND collation_name is not null
AND collation_name not in (SELECT collation_name FROM sys.databases WHERE database_id = DB_ID())

-- if for some reason you get an error about collation differences for the column query you could try this 
-- or something like this where you match the collations
SELECT DB_Name() as DatabaseName, SCHEMA_NAME(o.schema_id) as SchemaName, o.name as TableName, c.name as ColumnName, c.collation_name 
FROM sys.objects o
INNER JOIN sys.columns c on o.object_id = c.object_id
WHERE o.is_ms_shipped = 0
AND collation_name is not null
AND collation_name COLLATE SQL_Latin1_General_CP1_CI_AS not in (SELECT collation_name COLLATE SQL_Latin1_General_CP1_CI_AS 
                                                                FROM sys.databases 
                                                                WHERE database_id = DB_ID())