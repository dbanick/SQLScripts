-- Look at current expensive or blocked requests
SELECT  r.session_id ,
        r.[status] ,
        r.wait_type ,
        r.scheduler_id ,
        SUBSTRING(qt.[text], r.statement_start_offset / 2,
            ( CASE WHEN r.statement_end_offset = -1
                   THEN LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2
                   ELSE r.statement_end_offset
              END - r.statement_start_offset ) / 2) AS [statement_executing] ,
        DB_NAME(qt.[dbid]) AS [DatabaseName] ,
        OBJECT_NAME(qt.objectid) AS [ObjectName] ,
        r.cpu_time ,
        r.total_elapsed_time ,
        r.reads ,
        r.writes ,
        r.logical_reads ,
        r.plan_handle
FROM    sys.dm_exec_requests AS r
        CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS qt
WHERE   r.session_id > 50
ORDER BY r.scheduler_id ,
        r.[status] ,
        r.session_id ;
