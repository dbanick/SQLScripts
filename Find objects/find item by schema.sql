--find objects in a schema outside sys/dbo
SELECT SCHEMA_NAME(schema_id) as SchemaName, name as tableName
FROM sys.objects 
where SCHEMA_NAME(schema_id) != 'sys'
AND SCHEMA_NAME(schema_id) != 'dbo'


SELECT SCHEMA_NAME(schema_id) as SchemaName, name as tableName
FROM sys.tables 
where SCHEMA_NAME(schema_id) != 'sys'
AND SCHEMA_NAME(schema_id) != 'dbo'