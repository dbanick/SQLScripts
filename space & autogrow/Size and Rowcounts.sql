Declare @database_name varchar(500)
Declare @sqlstr1 varchar(max)

IF OBJECT_ID('tempdb..#temp_table') IS NOT NULL 
drop table #temp_table
 
create table #temp_table (
		l1 int
,		[database] varchar(500)     
,       [schema] varchar(max) 
,       [table] varchar(max) 
,       row_count INT 
,       reserved_MB VARCHAR(50) collate database_default 
,       data_MB VARCHAR(50) collate database_default 
,       index_size_MB VARCHAR(50) collate database_default 
,       unused_MB VARCHAR(50) collate database_default ) 


DECLARE UpdateAcct_cur CURSOR FOR
	select name  from sys.databases where name not in('master','model','msdb','tempdb','reportserver','reportservertempdb') 
	  and state_desc = 'ONLINE' AND is_read_only = 0 AND source_database_id IS NULL -- Exclude Snapshots  

	OPEN UpdateAcct_cur
	FETCH NEXT FROM UpdateAcct_cur  INTO @database_name
	WHILE @@FETCH_STATUS = 0
	BEGIN 

set  @sqlstr1 ='use ['+ @database_name+
'] Insert into #temp_table
 SELECT
      (ROW_NUMBER() OVER(ORDER BY t3.name, t2.name))%2 AS l1
      ,DB_NAME() AS [database]
      ,t3.name AS [schema]
      ,t2.name AS [table]
      ,t1.rows AS row_count
      ,((t1.reserved + ISNULL(a4.reserved,0))* 8) / 1024 AS reserved_MB 
      ,(t1.data * 8) / 1024 AS data_MB
      ,((CASE WHEN (t1.used + ISNULL(a4.used,0)) > t1.data THEN (t1.used + ISNULL(a4.used,0)) - t1.data ELSE 0 END) * 8) /1024 AS index_size_MB
      ,((CASE WHEN (t1.reserved + ISNULL(a4.reserved,0)) > t1.used THEN (t1.reserved + ISNULL(a4.reserved,0)) - t1.used ELSE 0 END) * 8)/1024 AS unused_MB
FROM
(SELECT 
       ps.object_id
      ,SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows]
      ,SUM (ps.reserved_page_count) AS reserved
      ,SUM (CASE WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END) AS data
      ,SUM (ps.used_page_count) AS used
  FROM sys.dm_db_partition_stats ps
  GROUP BY ps.object_id) AS t1
LEFT OUTER JOIN 
 (SELECT 
         it.parent_id
        ,SUM(ps.reserved_page_count) AS reserved
        ,SUM(ps.used_page_count) AS used
  FROM sys.dm_db_partition_stats ps
  INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id) WHERE it.internal_type IN (202,204)
  GROUP BY it.parent_id) AS a4 ON (a4.parent_id = t1.object_id)
INNER JOIN sys.tables t2  ON ( t1.object_id = t2.object_id) 
INNER JOIN sys.schemas t3 ON (t2.schema_id = t3.schema_id)
WHERE t2.type <> ''S'' and t2.type <> ''IT'''

exec (@sqlstr1)

	FETCH NEXT FROM UpdateAcct_cur  INTO @database_name
		
	END
	
CLOSE UpdateAcct_cur
DEALLOCATE UpdateAcct_cur



Declare @sqlcmd10 nvarchar(max)
set @sqlcmd10='
SELECT  [database],[schema],[table],row_count,reserved_MB,data_MB,index_size_MB,unused_MB
FROM #temp_table 
ORDER BY 
[database],[schema],[table],reserved_MB DESC'

exec master..sp_executesql @sqlcmd10
drop table #temp_table