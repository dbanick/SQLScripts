/***************************************************************************************************
Create Date:                    2021-07-14
Author:                         MSSQL Team
Description:                    This query is used for reporting, trending and triggering purposes for MSSQL servers where blocking and long running queries
                                will be monitored. Please see final output and notes for what columns will be used for these purposes.

Affected Zabbix Checks:         Blocking Queries
                                Long Running Queries

Parameter(s):

Prerequisites:
						
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2021-07-19          Scott Caldwell      Reviewed for style and coding practices
***************************************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* Create a temp table to gather any blocked spids, generating the blocking chain. */
CREATE TABLE #BlockingSPID (
  session_id smallint NOT NULL PRIMARY KEY, 
  blocking_session_id smallint NOT NULL
)

/* Insert into a temp table to gather any blocked spids, generating the blocking chain. */
INSERT INTO #BlockingSPID
SELECT session_id, blocking_session_id FROM sys.dm_exec_requests WHERE blocking_session_id <> 0 AND blocking_session_id <> session_id

/* Recursive CTE to build blocking chain. */
;WITH BlockingChainCTE
AS
(
SELECT
  session_id,
  blocking_session_id,
  blocking_session_id AS 'LeadBlocker',
  CONVERT(varchar(1000),CONVERT(varchar(100),session_id) + '-->' + CONVERT(varchar(100),blocking_session_id)) AS 'BlockingChain',
  CONVERT(int,0) AS 'Depth'
FROM #BlockingSPID
UNION ALL
SELECT
  c.session_id,
  b.blocking_session_id,
  b.blocking_session_id,
  CONVERT(varchar(1000),c.BlockingChain + '-->' + CONVERT(varchar(100),b.blocking_session_id)),
  c.Depth + 1
FROM BlockingChainCTE AS c
INNER JOIN #BlockingSPID AS b
  ON c.blocking_session_id = b.session_id
)

/* 
Final data which needs to be sent to Zabbix. 
		 
TRIGGER: Indicates the column is used for Zabbix triggering an alert
TRENDING: Indicates the column is used for Zabbix data trending
REPORTING: Indicates the column is used to report into Zabbix
MAPPING: Indicates this column is used for mapping other Zabbix checks
VALUES: Indicates we need to proivde the Zabbix Dev team the string values for the column results

NOTES:                  You have to ISNULL NULL results
COMMENT FORMAT:         Datatype | Column Type | Description
RESULTSET GRANULARITY:  1 row per SPID
*/

SELECT TOP 20
  ROW_NUMBER() OVER (ORDER BY SortMe,ElapsedTimeSS DESC,SPID) as 'ID', /* INT | Row number | REPORTING */
  ConnectionTime, /* DATETIME | Time of session connection | REPORTING */
  StartTime, /* DATETIME | Start time of batch | REPORTING */
  SPID, /* SMALLINT | Session ID | REPORTING,MAPPING */
  Blocker, /* SMALLINT | Session ID of immediate blocker | TRIGGER,REPORTING */
  LeadBlocker, /* SMALLINT | Session ID of lead blocker in the blocking chain | REPORTING,MAPPING */
  BlockingChain, /* VARCHAR | List of session IDs involved in the blocking chain | REPORTING */
  Threads, /* INT | Number of threads the SPID is using | REPORTING */
  DatabaseName, /* VARCHAR | Database name | REPORTING */
  LoginName, /* VARCHAR | Login name | REPORTING */
  CPU, /* INT | Measure of CPU utilized by the SPID | REPORTING */
  Reads, /* INT | Measure of reads by the SPID | REPORTING */
  LogicalReads, /* INT | Measure of logical reads by the SPID | REPORTING */
  Writes, /* INT | Measure of writes by the SPID | REPORTING */
  ElapsedTimeSS, /* INT | Elapsed time in seconds | REPORTING,TRIGGER(for long running) */
  BatchText, /* VARCHAR | Complete batch text executed | REPORTING */
  StatementText, /* VARCHAR | Current statement being executed in the batch | REPORTING */
  ProgramName, /* VARCHAR | Program name which invoked the session | REPORTING */
  HostName, /* VARCHAR | Host name which invoked the session | REPORTING */
  [Status], /* VARCHAR | Status of session | REPORTING */
  WaitResource, /* VARCHAR | Current wait resource | REPORTING */
  Command, /* VARCHAR | Session command | REPORTING */
  LastWaitType, /* VARCHAR | Last wait type | REPORTING */
  WaitTimeSS, /* INT | Wait time in seconds | REPORTING,TRIGGER(for blocking) */
  RequestedMemoryKB, /* BIGINT | Requested memory for session | REPORTING */
  GrantedMemoryKB, /* BIGINT | Granted memory for session (If RequestedMemoryKB>0 and GrantedMemoryKB=0, you have a memory grant pending for the session | REPORTING */
  PercentComplete /* REAL | Percent complete | REPORTING */
FROM (
  SELECT
    CASE WHEN ((r.blocking_session_id <> 0 OR bs.blocking_session_id IS NOT NULL) AND ISNULL(r.total_elapsed_time,30000) >=30000 AND ROW_NUMBER() OVER (ORDER BY ISNULL(r.total_elapsed_time,100000000) DESC) <=10) THEN 0 ELSE 1 END AS 'SortMe',
    c.connect_time AS 'ConnectionTime',
    COALESCE(r.start_time,s.last_request_start_time) AS 'StartTime',
    s.session_id AS 'SPID',
    ISNULL(r.blocking_session_id,0) AS 'Blocker',
    ISNULL(b.LeadBlocker,0) AS 'LeadBlocker',
    ISNULL(b.BlockingChain,'N/A') AS 'BlockingChain',
    ISNULL(x.Counts,0) AS 'Threads',
    ISNULL(DB_NAME(r.database_id),'N/A') AS 'DatabaseName',
    s.login_name AS 'LoginName',
    s.cpu_time AS 'CPU',
    s.reads AS 'Reads',
    s.logical_reads AS 'LogicalReads',
    s.writes AS 'Writes',
    ISNULL(r.total_elapsed_time,DATEDIFF(ms,c.connect_time,GETDATE()))/1000+1 AS 'ElapsedTimeSS',
    COALESCE(t.[text],ct.[text],'N/A') AS 'BatchText',
    ISNULL((SUBSTRING(COALESCE(t.[text],ct.[text],'N/A'),statement_start_offset / 2+1 
    , ((CASE WHEN statement_end_offset <0  THEN (LEN(CONVERT(nvarchar(MAX)
    ,COALESCE(t.[text],ct.[text],'N/A'))) * 2) ELSE statement_end_offset END) - statement_start_offset) / 2+1)),'N/A') AS 'StatementText',
    s.[program_name] AS 'ProgramName',
    HOST_NAME AS 'HostName',
    CASE WHEN r.session_id IS NULL THEN 'INACTIVE SPID' ELSE s.[status] END AS 'Status',
    ISNULL(NULLIF(r.wait_resource,''),'N/A') AS 'WaitResource',
    ISNULL(r.command,'N/A') AS 'Command',
    ISNULL(r.last_wait_type,'N/A') AS 'LastWaitType',
    ISNULL(r.wait_time,0)/1000 AS 'WaitTimeSS',
    ISNULL(mg.requested_memory_kb,0) AS 'RequestedMemoryKB',
    ISNULL(mg.granted_memory_kb,0) AS 'GrantedMemoryKB',
    ISNULL(percent_complete,0) AS 'PercentComplete'
  FROM sys.dm_exec_sessions AS s
  INNER JOIN sys.dm_exec_connections AS c
    ON s.session_id = c.session_id
  LEFT JOIN sys.dm_exec_requests AS r 
    ON s.session_id = r.session_id
  OUTER APPLY sys.dm_exec_sql_text (r.[sql_handle]) AS t
  OUTER APPLY sys.dm_exec_sql_text (c.most_recent_sql_handle) AS ct
  LEFT JOIN (SELECT x.BlockingChain,LeadBlocker, x.session_id, ROW_NUMBER() OVER (PARTITION BY x.session_id ORDER BY x.Depth DESC) AS 'RowNumber' FROM BlockingChainCTE AS x) AS b 
    ON b.session_id = r.session_id AND b.RowNumber = 1
  LEFT JOIN (SELECT COUNT(1) AS 'Counts',ost.session_id FROM sys.dm_os_tasks ost GROUP BY ost.session_id) AS x 
    ON  x.session_id=s.session_id
  LEFT JOIN sys.dm_exec_query_memory_grants AS mg
    ON mg.session_id = s.session_id
  LEFT JOIN (SELECT DISTINCT y.blocking_session_id FROM #BlockingSPID AS y) AS bs
    ON bs.blocking_session_id = s.session_id
  WHERE s.is_user_process = 1
  AND (r.session_id IS NOT NULL OR bs.blocking_session_id IS NOT NULL)
  AND s.session_id <> @@SPID
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
  UNION ALL SELECT 2,'1/1/1900','1/1/1900',0,0,0,'N/A',0,'N/A','N/A',0,0,0,0,0,'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A',0,0,0,0
) AS z
ORDER BY SortMe, ElapsedTimeSS DESC,SPID
DROP TABLE #BlockingSPID