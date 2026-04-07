-- Missing Indexes in current database by Index Advantage
SELECT  user_seeks * avg_total_user_cost * ( avg_user_impact * 0.01 )
                                                       AS [index_advantage] ,
        migs.last_user_seek ,
        mid.[statement] AS [Database.Schema.Table] ,
        mid.equality_columns ,
        mid.inequality_columns ,
        mid.included_columns ,
        migs.unique_compiles ,
        migs.user_seeks ,
        migs.avg_total_user_cost ,
        migs.avg_user_impact
FROM    sys.dm_db_missing_index_group_stats AS migs WITH ( NOLOCK )
        INNER JOIN sys.dm_db_missing_index_groups AS mig WITH ( NOLOCK )
           ON migs.group_handle = mig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details AS mid WITH ( NOLOCK )
           ON mig.index_handle = mid.index_handle
WHERE   mid.database_id = DB_ID()
ORDER BY index_advantage DESC ;


--- Index Read/Write stats (all tables in current DB)
SELECT  OBJECT_NAME(s.[object_id]) AS [ObjectName] ,
        i.name AS [IndexName] ,
        i.index_id ,
        user_seeks + user_scans + user_lookups AS [Reads] ,
        user_updates AS [Writes] ,
        i.type_desc AS [IndexType] ,
        i.fill_factor AS [FillFactor]
FROM    sys.dm_db_index_usage_stats AS s
        INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND i.index_id = s.index_id
        AND s.database_id = DB_ID()
ORDER BY OBJECT_NAME(s.[object_id]) ,
        writes DESC ,
        reads DESC ;

/*
create table #rdx_index_stats ([database] varchar(200), [table] varchar(200), IndexName varchar(200), reads int, writes int, indexType varchar(400), fill_factor int)

insert into #rdx_index_stats
exec sp_MSforeachdb'
use [?]

SELECT  db_name() as [database],
		OBJECT_NAME(s.[object_id]) AS [ObjectName] ,
        i.name AS [IndexName] ,
        --i.index_id ,
        user_seeks + user_scans + user_lookups AS [Reads] ,
        user_updates AS [Writes] ,
        i.type_desc AS [IndexType] ,
        i.fill_factor AS [FillFactor]
FROM    sys.dm_db_index_usage_stats AS s
        INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
WHERE   OBJECTPROPERTY(s.[object_id], ''IsUserTable'') = 1
        AND i.index_id = s.index_id
        AND s.database_id = DB_ID()
ORDER BY OBJECT_NAME(s.[object_id]) ,
        writes DESC ,
        reads DESC ;
'

select * from #rdx_index_stats
go
drop table #rdx_index_stats

*/

-- List unused indexes
SELECT  OBJECT_NAME(i.[object_id]) AS [Table Name] ,
        i.name
FROM    sys.indexes AS i
        INNER JOIN sys.objects AS o ON i.[object_id] = o.[object_id]
WHERE   i.index_id NOT IN ( SELECT  s.index_id
                            FROM    sys.dm_db_index_usage_stats AS s
                            WHERE   s.[object_id] = i.[object_id]
                                    AND i.index_id = s.index_id
                                    AND database_id = DB_ID() )
        AND o.[type] = 'U'
ORDER BY OBJECT_NAME(i.[object_id]) ASC ;


-- Possible Bad NC Indexes (writes > reads)
SELECT  OBJECT_NAME(s.[object_id]) AS [Table Name] ,
        i.name AS [Index Name] ,
        i.index_id ,
        user_updates AS [Total Writes] ,
        user_seeks + user_scans + user_lookups AS [Total Reads] ,
        user_updates - ( user_seeks + user_scans + user_lookups )
            AS [Difference]
FROM    sys.dm_db_index_usage_stats AS s WITH ( NOLOCK )
        INNER JOIN sys.indexes AS i WITH ( NOLOCK )
            ON s.[object_id] = i.[object_id]
            AND i.index_id = s.index_id
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND s.database_id = DB_ID()
        AND user_updates > ( user_seeks + user_scans + user_lookups )
        AND i.index_id > 1
ORDER BY [Difference] DESC ,
        [Total Writes] DESC ,
        [Total Reads] ASC ;

-- Table and row count information   
SELECT  OBJECT_NAME(ps.[object_id]) AS [TableName] ,
        i.name AS [IndexName] ,
        SUM(ps.row_count) AS [RowCount]
FROM    sys.dm_db_partition_stats AS ps
        INNER JOIN sys.indexes AS i ON i.[object_id] = ps.[object_id]
                                       AND i.index_id = ps.index_id
WHERE   i.type_desc IN ( 'CLUSTERED', 'HEAP' )
        AND i.[object_id] > 100
        AND OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys'
GROUP BY ps.[object_id] ,
        i.name
ORDER BY SUM(ps.row_count) DESC ;
