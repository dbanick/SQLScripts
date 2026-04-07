--this script will run sp_estimate_data_compression_savings against each object in a database to give an estimate for compression savings

set nocount on;
--Get the list of the physical objects which are not already compressed in a temp table
SELECT top 30 [t].schema_id, [p].[object_id], [p].[index_id] index_no, [p].[partition_number] AS [Partition],
    [p].[data_compression_desc] AS [Compression],
	(select SUM(s.[used_page_count]) * 8
	FROM sys.dm_db_partition_stats AS s
	where s.object_id = [p].[object_id] and s.index_id = p.index_id) AS IndexSizeKB,
	[u].user_updates + [u].system_updates as [Updates],
	[u].user_seeks + [u].system_seeks as [Seeks],
	[u].user_scans + [u].system_scans as [Scans]
into #objects_with_stats
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
INNER JOIN [sys].[indexes] AS i ON i.object_id = p.object_id and i.index_id = p.index_id
INNER JOIN sys.filegroups f
	ON i.data_space_id = f.data_space_id
LEFT JOIN sys.dm_db_index_usage_stats AS [u] 
	ON [u].[object_id] = [p].[object_id] and [u].[index_id] = [p].[index_id]
WHERE
	[p].[data_compression_desc] <> 'PAGE' and [p].[data_compression_desc] <> 'COLUMNSTORE'
	and i.is_disabled = 0
	and f.name in ('PRIMARY', 'fgmain')
order by IndexSizeKB desc;

--Create a temp table for PAGE compression estimates
create table #estimates_tmp_p (
	[object_name] sysname, 
	[schema_name] sysname, 
	index_id int,
	partition_number int, 
	current_size bigint, 
	estimated_size bigint,
	sample_size bigint,
	sample_estimated bigint
);

--Create a temp table for ROW compression estimates
create table #estimates_tmp_r (
	[object_name] sysname, 
	[schema_name] sysname, 
	index_id int,
	partition_number int, 
	current_size bigint, 
	estimated_size bigint,
	sample_size bigint,
	sample_estimated bigint
);

--Use a cursor to iterate for each object
DECLARE @IndexCursor CURSOR;
DECLARE @sch sysname, @tbl sysname, @idx int, @prt int;

SET @IndexCursor = CURSOR FOR
    select SCHEMA_NAME([schema_id]), OBJECT_NAME([object_id]), index_no, Partition from #objects_with_stats;

OPEN @IndexCursor;
FETCH NEXT FROM @IndexCursor INTO @sch, @tbl, @idx, @prt;

WHILE @@FETCH_STATUS = 0
    BEGIN
		--Populate temp tables with the estimates for each object
		INSERT INTO #estimates_tmp_p ([object_name], [schema_name], index_id, partition_number, current_size, estimated_size, sample_size, sample_estimated)
		EXEC sp_estimate_data_compression_savings @sch, @tbl, @idx, @prt, 'PAGE';
		INSERT INTO #estimates_tmp_r ([object_name], [schema_name], index_id, partition_number, current_size, estimated_size, sample_size, sample_estimated)
		EXEC sp_estimate_data_compression_savings @sch, @tbl, @idx, @prt, 'ROW';
		--Take the next record
		FETCH NEXT FROM @IndexCursor INTO @sch, @tbl, @idx, @prt;
    END; 

CLOSE @IndexCursor;
DEALLOCATE @IndexCursor;



----
--Show the resultset ordered by the size of an index
select DB_NAME() [Database], SCHEMA_NAME(idx.[schema_id]) [schema], OBJECT_NAME(idx.[object_id]) [table], f.name as filegroupname,
	p.data_compression_desc, i.fill_factor,
	idx.index_no, idx.partition, idx.IndexSizeKB, idx.Updates, idx.Seeks, idx.Scans, rce.row_est_prc_save, pce.page_est_prc_save
from
	#objects_with_stats idx
inner join
	(select OBJECT_ID('['+[schema_name]+'].['+[object_name]+']') [object_id], SCHEMA_ID([schema_name]) [schema_id], index_id, partition_number, 
		case when current_size>0 
			then 100.0*(current_size - estimated_size)/current_size 
			else NULL 
		end page_est_prc_save
	from #estimates_tmp_p p) pce
on pce.[schema_id] = idx.[schema_id] and pce.[object_id] = idx.[object_id]
	and pce.index_id = idx.index_no and pce.partition_number = idx.partition
inner join
	(select OBJECT_ID('['+[schema_name]+'].['+[object_name]+']') [object_id], SCHEMA_ID([schema_name]) [schema_id], index_id, partition_number, 
		case when current_size>0 
			then 100.0*(current_size - estimated_size)/current_size 
			else NULL 
		end row_est_prc_save
	from #estimates_tmp_r r) rce
on pce.[schema_id] = rce.[schema_id] and pce.[object_id] = rce.[object_id]
	and pce.index_id = rce.index_id and pce.partition_number = rce.partition_number
join sys.indexes i 
	on i.object_id = idx.[object_id]
INNER JOIN sys.filegroups f
	ON i.data_space_id = f.data_space_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
order by idx.IndexSizeKB desc;

--Do cleanup
drop table #objects_with_stats
drop table #estimates_tmp_p
drop table #estimates_tmp_r
