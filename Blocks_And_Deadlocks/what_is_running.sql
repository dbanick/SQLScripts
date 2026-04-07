SELECT r.cpu_time, 
       r.logical_reads, 
       r.session_id 
INTO   #temp 
FROM   sys.dm_exec_sessions AS s 
       INNER JOIN sys.dm_exec_requests AS r 
               ON s.session_id = r.session_id 
                  AND s.last_request_start_time = r.start_time 
WHERE  is_user_process = 1 

WAITFOR delay '00:00:01' 

SELECT Substring(h.text, ( r.statement_start_offset / 2 ) + 1, 
              ( ( CASE r.statement_end_offset 
              WHEN -1 THEN Datalength(h.text) 
              ELSE r.statement_end_offset 
                                                                   END - 
       r.statement_start_offset ) / 2 ) + 1) AS text, 
       r.blocking_session_id, 
       r.cpu_time - t.cpu_time               AS CPUDiff, 
       r.logical_reads - t.logical_reads     AS ReadDiff, 
       p.query_plan, 
       r.wait_type, 
       r.wait_time, 
       r.last_wait_type, 
       r.wait_resource, 
       r.command, 
       r.database_id, 
       
       r.granted_query_memory, 
       r.session_id, 
       r.reads, 
       r.writes, 
       r.row_count, 
       s.[host_name], 
       s.program_name, 
       s.login_name 
FROM   sys.dm_exec_sessions AS s 
       INNER JOIN sys.dm_exec_requests AS r 
               ON s.session_id = r.session_id 
                  AND s.last_request_start_time = r.start_time 
       FULL OUTER JOIN #temp AS t 
                    ON t.session_id = s.session_id 
       CROSS apply sys.Dm_exec_sql_text(r.sql_handle) h 
       CROSS apply sys.Dm_exec_query_plan(r.plan_handle) p 
WHERE  r.session_id <> @@SPID 
ORDER  BY 3 DESC 

DROP TABLE #temp 