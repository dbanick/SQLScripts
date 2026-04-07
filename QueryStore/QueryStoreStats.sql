
DECLARE @StartDate datetimeoffset(7) = '2021-04-23 11:17:47 -04:00' -- -4 is EST
DECLARE @EndDate datetimeoffset(7) = '2021-04-23 12:27:47 -04:00' -- -4 is EST
DECLARE @QueryTextFilter varchar(1000) = '' -- '%Text to search%' leave blank or null for "all". Wildcards accepted (%)
DECLARE @ObjectName varchar(1000) = '' -- 'spGetProcedureName' leave blank or null for "all"

SELECT TOP 50
  p.query_id as 'QueryID',
  ISNULL(OBJECT_NAME(q.object_id),'') as 'ObjectName',
  qt.query_sql_text as 'QueryText',
  SUM(rs.count_executions) as 'ExecutionCount',
  CONVERT(BIGINT,CONVERT(FLOAT, SUM(rs.avg_cpu_time*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*0.001) as 'AvgCPUTime',   
  CONVERT(BIGINT,CONVERT(FLOAT, SUM(rs.avg_cpu_time*rs.count_executions))*0.001) as 'TotalCPUTime', 
  CONVERT(BIGINT,CONVERT(FLOAT, SUM(rs.avg_duration*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*0.001) as 'AvgDuration',
  CONVERT(BIGINT,CONVERT(FLOAT, SUM(rs.avg_duration*rs.count_executions))*0.001) 'TotalDuration',
  SUM(ws.NetworkIOWait) as 'TotalCPUWait',
  SUM(ws.NetworkIOWait) as 'TotalNetworkIOWait',
  SUM(ws.MemoryWait) as 'TotalMemoryWait',
  SUM(ws.LatchWait) as 'TotalLatchWait',
  SUM(ws.LockWait) as 'TotalLockWait',
  SUM(ws.BufferLatchWait) as 'TotalBufferLatchWait',
  SUM(ws.BufferIOWait) as 'TotalBufferIOWait',
  SUM(ws.ParralelismWait) as 'TotalParallelismWait',
  SUM(ws.OtherDiskIOWait) as 'TotalOtherDiskIOWait',
  SUM(ws.SQLCLRWait) as 'TotalSQLCLRWait',
  SUM(ws.TranLogIOWait) as 'TotalTranLogIOWait',
  SUM(ws.ReplicationWait) as 'TotalReplicationWait',
  SUM(ws.OtherWait) as 'TotalOtherWait',
  COUNT(distinct p.plan_id) as 'PlanCount',
  TRY_CONVERT( XML, p.query_plan) AS 'QueryPlan'
FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id
    JOIN sys.query_store_query q ON q.query_id = p.query_id
    JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
    LEFT JOIN
      ( SELECT 
          wsx.plan_id,
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'CPU' THEN avg_query_wait_time_ms ELSE 0 END)) as 'CPUWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Network IO' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'NetworkIOWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Memory' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'MemoryWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Latch' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'LatchWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Lock' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'LockWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Buffer Latch' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'BufferLatchWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Buffer IO' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'BufferIOWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Parallelism' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'ParralelismWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Other Disk IO' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'OtherDiskIOWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'SQL CLR' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'SQLCLRWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Tran Log IO' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'TranLogIOWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc = 'Replication' THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'ReplicationWait',
          CONVERT(BIGINT,SUM(CASE WHEN wsx.wait_category_desc NOT IN ('Network IO','Memory','Other Disk IO','CPU','SQL CLR','Tran Log IO','Replication','Latch','Lock','Buffer Latch','Buffer IO') THEN wsx.avg_query_wait_time_ms ELSE 0 END)) as 'OtherWait'
        FROM sys.query_store_wait_stats wsx 
        GROUP BY wsx.plan_id
      )ws ON ws.plan_id = p.plan_id 
WHERE (qt.query_sql_text like @QueryTextFilter OR ISNULL(@QueryTextFilter,'') = '')
AND (OBJECT_NAME(q.object_id) = @ObjectName OR ISNULL(@ObjectName,'') = '')
AND NOT (rs.first_execution_time > @EndDate OR rs.last_execution_time < @StartDate)
GROUP BY p.query_id, qt.query_sql_text, q.object_id,p.query_plan
HAVING COUNT(distinct p.plan_id) >= 1
ORDER BY AvgDuration DESC
