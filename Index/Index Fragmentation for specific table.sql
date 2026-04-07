DECLARE @db_id SMALLINT;
DECLARE @object_id INT;

SET @db_id = DB_ID(N'JDE_PRODUCTION');
SET @object_id = OBJECT_ID(N'JDE_PRODUCTION.PRODDTA.F0911');

IF @db_id IS NULL
BEGIN;
    PRINT N'Invalid database';
END;
ELSE IF @object_id IS NULL
BEGIN;
    PRINT N'Invalid object';
END;
ELSE
BEGIN;
	SELECT 'Table Name' = o.name,'Index Name' = b.name, 'Statistics Date' = STATS_DATE(b.object_id, b.index_id)
	,a.Index_type_desc
	,a.page_count
	,a.avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (@db_id, @object_id, NULL, NULL, 'LIMITED') as a
	JOIN sys.objects o on o.object_id=a.object_id
	JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id

END;
GO