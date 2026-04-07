SELECT
	 a.session_id
    ,(select count(e.spid) from master..sysprocesses e where e.spid = a.session_id) as PCPU
	,a.blocking_session_id
	,a.command
	,db_name(a.database_id) as 'DBName'
	,a.start_time
	,a.open_transaction_count
	,a.cpu_time
	,a.total_elapsed_time
	,a.wait_type
	,a.last_wait_type
	,a.reads
	,a.writes
	,a.logical_reads 
	,a.lock_timeout
	,c.host_name
	,c.program_name
	,c.login_name
	,c.login_time
	,b.text
	,d.query_plan 
	--,*
	FROM sys.dm_exec_requests a
	OUTER APPLY sys.dm_exec_sql_text(a.sql_handle) b
	OUTER APPLY sys.dm_exec_query_plan (a.plan_handle) d
	inner join sys.dm_exec_sessions c on a.session_id=c.session_id
	WHERE a.status <> 'background'
	AND a.command <> 'Awaiting Command'
	AND c.is_user_process <> 0
	AND a.session_id <> @@SPID