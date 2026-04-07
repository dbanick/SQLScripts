https://www.sqlskills.com/blogs/paul/tracking-page-splits-using-the-transaction-log/

USE DB
GO
SELECT
    [AllocUnitName] AS N'Index',
    (CASE [Context]
        WHEN N'LCX_INDEX_LEAF' THEN N'Nonclustered'
        WHEN N'LCX_CLUSTERED' THEN N'Clustered'
        ELSE N'Non-Leaf'
    END) AS [SplitType],
    COUNT (1) AS [SplitCount]
FROM
    fn_dblog (NULL, NULL)
WHERE
    [Operation] = N'LOP_DELETE_SPLIT'
GROUP BY [AllocUnitName], [Context];
GO

https://www.sqlskills.com/blogs/jonathan/tracking-problematic-pages-splits-in-sql-server-2012-extended-events-no-really-this-time/

--All page Splits for all databases

-- If the Event Session exists DROP it
IF EXISTS (SELECT 1 
            FROM sys.server_event_sessions 
            WHERE name = 'TrackPageSplits_AllDBs')
    DROP EVENT SESSION [TrackPageSplits_AllDBs] ON SERVER

-- Create the Event Session to track LOP_DELETE_SPLIT transaction_log operations in the server
CREATE EVENT SESSION [TrackPageSplits_AllDBs]
ON    SERVER
ADD EVENT sqlserver.transaction_log(
    WHERE operation = 11  -- LOP_DELETE_SPLIT 
)
ADD TARGET package0.histogram(
    SET filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- Event Column
        source = 'database_id');
GO
        
-- Start the Event Session
ALTER EVENT SESSION [TrackPageSplits_AllDBs]
ON SERVER
STATE=START;
GO


SELECT 
    n.value('(value)[1]', 'bigint') AS database_id,
    DB_NAME(n.value('(value)[1]', 'bigint')) AS database_name,
    n.value('(@count)[1]', 'bigint') AS split_count
FROM
(SELECT CAST(target_data as XML) target_data
 FROM sys.dm_xe_sessions AS s 
 JOIN sys.dm_xe_session_targets t
     ON s.address = t.event_session_address
 WHERE s.name = 'TrackPageSplits_AllDBs'
  AND t.target_name = 'histogram' ) as tab
CROSS APPLY target_data.nodes('HistogramTarget/Slot') as q(n)


------------------------------------------------

--page splits on individual database

-- Drop the Event Session so we can recreate it 
-- to focus on the highest splitting database
DROP EVENT SESSION [TrackPageSplits_by_DB] 
ON SERVER

-- Create the Event Session to track LOP_DELETE_SPLIT transaction_log operations in the server
CREATE EVENT SESSION [TrackPageSplits_by_DB]
ON    SERVER
ADD EVENT sqlserver.transaction_log(
    WHERE operation = 11  -- LOP_DELETE_SPLIT 
      AND database_id = 8 -- CHANGE THIS BASED ON TOP SPLITTING DATABASE!
)
ADD TARGET package0.histogram(
    SET filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- Event Column
        source = 'alloc_unit_id');
GO

-- Start the Event Session Again
ALTER EVENT SESSION [TrackPageSplits_by_DB]
ON SERVER
STATE=START;
GO


-- Query Target Data to get the top splitting objects in the database:
USE DB
go
SELECT db_name() as [Database],
    o.name AS table_name,
    i.name AS index_name,
    tab.split_count,
    i.fill_factor
FROM (    SELECT 
            n.value('(value)[1]', 'bigint') AS alloc_unit_id,
            n.value('(@count)[1]', 'bigint') AS split_count
        FROM
        (SELECT CAST(target_data as XML) target_data
         FROM sys.dm_xe_sessions AS s 
         JOIN sys.dm_xe_session_targets t
             ON s.address = t.event_session_address
         WHERE s.name = 'TrackPageSplits_by_DB'
          AND t.target_name = 'histogram' ) as tab
        CROSS APPLY target_data.nodes('HistogramTarget/Slot') as q(n)
) AS tab
JOIN sys.allocation_units AS au
    ON tab.alloc_unit_id = au.allocation_unit_id
JOIN sys.partitions AS p
    ON au.container_id = p.partition_id
JOIN sys.indexes AS i
    ON p.object_id = i.object_id
        AND p.index_id = i.index_id
JOIN sys.objects AS o
    ON p.object_id = o.object_id
WHERE o.is_ms_shipped = 0;