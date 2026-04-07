/*
	Script:		startup_health.sql
	Author:		Nathanael Sellars
	Date:		March 31, 2016
	Version:	0.4b

	Metrics Checked:
	SQL 2005+	database state, replication, mirroring, error log,
				log shipping, error log scrape
	SQL 2012+	database state, replication, mirroring, error log,
				AlwaysOn, log shipping, error log scrape

	Notes: missed jobs (weekly and monthly), downtime duration and event viewer scrape scripting are not done.

	Health Metrics:
		Database State - DB must be in state 0 or 1 if mirrored/LS
		Replication - Log reader and distribution agents must be running
		Mirroring - Must be synchronized state with started endpoints
		AlwaysOn - Async mode must be "synchronizing"; sync mode must be
			"synchronized"; all other status return unhealthy
		Log Shipping - time since last copy/backup/restore must be below threshold
		Error log - If any of the errors in the filter list are found, this fails.
		Missed Jobs - If time since last run is more than interval between runs, it was missed.
*/

set nocount on

-- variables
declare @curjob sysname
declare @curdb sysname
declare @curlsrole char(1)
declare @curbkpdate datetime
declare @curresdate datetime
declare @curbkpthresh int
declare @curresthresh int
declare @numerror int
declare @untilnext bigint
declare @subtype int
declare @subinterval int
declare @xminsec bit
declare @xhours bit
declare @daily bit
declare @weekly bit
declare @monthly bit
declare @lastrun datetime
declare @sincelast bigint
declare @nextrun datetime
declare @startup datetime
declare @downtime bigint
declare @sqlversion int
	set @sqlversion = SUBSTRING(CAST(SERVERPROPERTY('productversion') as NVARCHAR(25)),0,CHARINDEX('.',CAST(SERVERPROPERTY('productversion') as NVARCHAR(25))))

-- create temporary tables
create table #dbprop (dbname sysname, dbstate int, is_published bit, is_subscribed bit, is_logship bit, is_mirrored bit, state_ok bit)
create table #log1 (LogDate datetime, ProcessInfo nvarchar(100), Text nvarchar(max))
create table #log2 (LogDate datetime, ProcessInfo nvarchar(100), Text nvarchar(max))
create table #health (Metric nvarchar(25), Healthy bit)

-- get startup and shutdown times
set @startup = (select login_time from sys.sysprocesses where spid = 1)

-- populate database properties
insert into #dbprop (dbname, dbstate, is_published)
	select name, [state], is_published
	from sys.databases

declare db_cursor cursor for
	select dbname from #dbprop where dbstate = 0

open db_cursor
fetch next from db_cursor into @curdb

while @@FETCH_STATUS = 0
begin
	update #dbprop
		set is_subscribed = case when OBJECT_ID(@curdb+'.dbo.MSreplication_objects') IS NOT NULL then 1 else 0 end
	where dbname = @curdb
	
	fetch next from db_cursor into @curdb
end

close db_cursor
deallocate db_cursor

-- perform replication checks
-- intialize #health check
insert into #health (Metric, Healthy) values ('Replication',NULL)

-- create temp table
create table #repjobs (jobname sysname, jobid nvarchar(100), jobtype nvarchar(50), job_started datetime, job_finished datetime, [status] nvarchar(25));

-- check replication health
with rep_cte
as
(
	select j.name [jobname], j.job_id, j.category_id, c.name [category], max(a.start_execution_date) [job_started]
	from msdb.dbo.sysjobs j
	inner join msdb.dbo.syscategories c
		on j.category_id = c.category_id
	inner join msdb.dbo.sysjobactivity a
		on j.job_id = a.job_id
	where j.category_id in (10,13)
	group by j.name, j.job_id, j.category_id, c.name
)
insert into #repjobs
	select 
		r.jobname, 
		r.job_id, 
		r.category,
		r.job_started,
		a.stop_execution_date [job_finished],
		[status] = 
			case 
			when r.job_started is not null and a.stop_execution_date is null then 'RUNNING' 
			else 'NOT RUNNING' 
			end
	from rep_cte r
	inner join msdb.dbo.sysjobactivity a
		on r.job_id = a.job_id
			and a.start_execution_date >= r.job_started
	where r.category_id in (10,13)

-- update health log with replication status
update #health
	set Healthy = 
		case
			when (select count(*) from #repjobs where status = 'NOT RUNNING') > 0 then 0
			else 1
		end
	where Metric = 'Replication'

-- perform mirroring check
-- intialize #health check
insert into #health (Metric, Healthy) values ('Mirroring',NULL)

-- check mirroring health
if (select count(*) from sys.database_mirroring) = 0
begin
	update #health 
		set Healthy = 1 
	where Metric = 'Mirroring'
end

else
begin
	-- create mirroring temp tables
	create table #mirrors (dbname sysname, mirror_role nvarchar(25), mirror_status nvarchar(25))
	create table #endpoints (endpoint_name sysname, endpoint_role nvarchar(25), endpoint_status nvarchar(25))

	-- populate temp tables
	insert into #mirrors
		select db_name(database_id), mirroring_role_desc, mirroring_state_desc from sys.database_mirroring
		where mirroring_guid is not null

	insert into #endpoints
		select name, role_desc, state_desc from sys.database_mirroring_endpoints
		where type_desc = 'DATABASE_MIRRORING'

	-- if mirroring endpoints are all running
	if (select count(*) from #endpoints where endpoint_status <> 'STARTED') = 0
	begin
		-- if all mirrors are in sync and endpoints are running
		if (select count(*) from #mirrors where mirror_status <> 'SYNCHRONIZED') = 0
		begin
			update #health
				set Healthy = 1
			where Metric = 'Mirroring'
		end

		-- if endpoints are running but mirrors are not in sync
		else
		begin
			update #health
				set Healthy = 0
			where Metric = 'Mirroring'
		end
	end

	-- if endpoints are not running
	else
	begin
		update #health
				set Healthy = 0
			where Metric = 'Mirroring'
	end			
end

-- perform log shipping checks
-- intialize #health check if LS is in use
if (select count(*) from msdb.dbo.log_shipping_primary_databases) > 0 or (select count(*) from msdb.dbo.log_shipping_secondary_databases) > 0
begin
	insert into #health (Metric, Healthy) values ('LogShipping',NULL)

	-- create log shipping temp table
	create table #logship (dbname sysname, lsrole char(1), last_backup datetime, last_restore datetime, bkp_thresh int, res_thresh int,
		since_bkp as datediff(minute,last_backup,getdate()), since_restore as datediff(minute,last_restore,getdate()))

	-- check if instance is both a primary and secondary
	if (select count(*) from msdb.dbo.log_shipping_primary_databases) > 0 and (select count(*) from msdb.dbo.log_shipping_secondary_databases) > 0
	begin
		-- populate temp table with details
		insert into #logship
			select primary_database, 'P', last_backup_date, NULL, backup_threshold, NULL from msdb.dbo.log_shipping_monitor_primary
			union all
			select secondary_database, 'S', NULL, last_restored_date, NULL, restore_threshold from msdb.dbo.log_shipping_monitor_secondary

		-- check for health
		if (select count(*) from #logship where since_bkp >= bkp_thresh) > 0 or (select count(*) from #logship where since_restore >= res_thresh) > 0
		begin
			update #health
				set Healthy = 0
			where Metric = 'LogShipping'
		end
	
		else
		begin
			update #health
				set Healthy = 1
			where Metric = 'LogShipping'
		end 
	end

	-- check if instance is a log shipping primary
	else if (select count(*) from msdb.dbo.log_shipping_primary_databases) > 0
	begin
		-- populate temp table with details
		insert into #logship
			select primary_database, 'P', last_backup_date, NULL, backup_threshold, NULL from msdb.dbo.log_shipping_monitor_primary

		-- check for health
		if (select count(*) from #logship where since_bkp >= bkp_thresh) > 0
		begin
			update #health
				set Healthy = 0
			where Metric = 'LogShipping'
		end
	
		else
		begin
			update #health
				set Healthy = 1
			where Metric = 'LogShipping'
		end 
	end

	-- check if instance is a log shipping secondary
	else if (select count(*) from msdb.dbo.log_shipping_secondary_databases) > 0
	begin
		-- populae temp table with details
		insert into #logship
			select secondary_database, 'S', NULL, last_restored_date, NULL, restore_threshold from msdb.dbo.log_shipping_monitor_secondary

		-- check for health
		if (select count(*) from #logship where since_restore >= res_thresh) > 0
		begin
			update #health
				set Healthy = 0
			where Metric = 'LogShipping'
		end
	
		else
		begin
			update #health
				set Healthy = 1
			where Metric = 'LogShipping'
		end 
	end
end

-- perform AlwaysOn AG check if SQL 2012+
if @sqlversion >= 11
begin
	-- see if AOAG is configured and running
	if SERVERPROPERTY('IsHadrEnabled') = 1 and SERVERPROPERTY('HadrManagerStatus') = 1
	begin
		-- intialize #health check
		insert into #health (Metric, Healthy) values ('AlwaysOnAG',NULL)

		-- create AOAG temp table
		create table #AOAGStatus (AOGroupName sysname, AOListenerStatus nvarchar(25), AOHost nvarchar(50), AvailMode nvarchar(25), AODatabase sysname, AORole nvarchar(25), AOState nvarchar(50), is_suspended bit,
			suspend_reason nvarchar(1000), log_send_queue_size bigint, log_send_rate bigint, redo_queue_size bigint, filestream_send_rate bigint, page_repair_count bigint)

		-- populate AOAG temp table
		insert into #AOAGStatus
			SELECT AGC.name as 'AOGroupName'
			, (select state_desc from sys.availability_group_listener_ip_addresses where ip_address in (select ip_address from sys.dm_tcp_listener_states)) AS 'AOListenerStatus'
			, (SELECT AR.replica_server_name FROM sys.availability_replicas as AR WHERE AR.replica_id=DRS.replica_id) as 'AOHost'
			, (SELECT AR.availability_mode_desc FROM sys.availability_replicas as AR WHERE AR.replica_id=DRS.replica_id) as 'AvailMode'
			, ADC.database_name as 'AODatabase'
			, (SELECT role_desc FROM sys.dm_hadr_availability_replica_states as ARS WHERE ARS.replica_id=DRS.replica_id) as 'AORole'
			, ISNULL(DRS.synchronization_state_desc, ' ') as synchronization_state_desc
			, DRS.is_suspended
			, ISNULL(DRS.suspend_reason_desc, ' ') as suspend_reason_desc
			, ISNULL(DRS.log_send_queue_size,0) as log_send_queue_size
			, ISNULL(DRS.log_send_rate,0) as log_send_rate
			, ISNULL(DRS.redo_queue_size,0) as redo_queue_size
			, ISNULL(DRS.redo_rate,0) as redo_rate
			, ISNULL(DRS.filestream_send_rate,0) as filestream_send_rate
			, (SELECT COUNT(database_id) FROM sys.dm_hadr_auto_page_repair as APR WHERE APR.database_id=DRS.database_id AND APR.modification_time >= DATEADD(dd,-10,GETDATE())) as 'AutoPageRepairCount'
			FROM sys.availability_groups_cluster as AGC
			LEFT JOIN sys.availability_databases_cluster as ADC
			ON AGC.group_id=ADC.group_id
			LEFT JOIN sys.dm_hadr_database_replica_states as DRS
			ON ADC.group_id=DRS.group_id AND ADC.group_database_id=DRS.group_database_id

		-- check AOAG health
		-- looks for offline listener, sync commit not in synchronized state, async not in synchronizing, replica in unhealthy state
		if (select count(*) from #AOAGStatus where AOListenerStatus <> 'ONLINE' or (AvailMode = 'SYNCHRONOUS_COMMIT' and AOState <> 'SYNCHRONIZED') or 
			(AvailMode = 'ASYNCHRONOUS_COMMIT' and AOState <> 'SYNCHRONIZING') or AOState in ('NOT SYNCHRONIZING','REVERTING','INITIALIZING')) > 0
		begin
			update #health
				set Healthy = 0
			where Metric = 'AlwaysOnAG'
		end

		else
		begin
			update #health
				set Healthy = 1
			where Metric = 'AlwaysOnAG'
		end
	end

	-- if server is setup for AO but the manager is not online and healthy
	else if SERVERPROPERTY('IsHadrEnabled') = 1 and SERVERPROPERTY('HadrManagerStatus') = 2
	begin
		-- intialize #health check
		insert into #health (Metric, Healthy) values ('AlwaysOnAG',NULL)

		-- update #health table
		update #health
			set Healthy = 0
		where Metric = 'AlwaysOnAG'
	end		
end

-- check databases are in healthy state
-- intialize #health check
insert into #health (Metric, Healthy) values ('DBState',NULL)

-- update columns to denote if LS or mirroring is being used
if object_id('tempdb.dbo.#logship') is not null and object_id('tempdb.dbo.#mirrors') is not null
begin
	update #dbprop
		set is_logship = case
			when dbname in (select dbname from #logship) then 1 
			when is_logship is null then 0 end,
		is_mirrored = case
			when dbname in (select dbname from #mirrors) then 1 
			when is_mirrored is null then 0 end
end
else
begin
	update #dbprop
		set is_logship = 0, is_mirrored = 0
end

-- set individual db status to healthy or not
update p1
	set p1.state_ok = 1
from #dbprop p1
inner join #dbprop p2 on p1.dbname = p2.dbname
where p2.dbstate = 0
	or p2.dbstate = 1 and (p2.is_logship = 1 or p2.is_mirrored = 1)

update #dbprop
	set state_ok = 0
where state_ok is null


-- update #health table
-- DBState IDs
-- 1 = RESTORING, 2 = RECOVERING, 3 = RECOVERY_PENDING, 4 = SUSPECT, 
-- 5 = EMERGENCY, 6 = OFFLINE, 10 = OFFLINE_SECONDARY
if (select count(*) from #dbprop where state_ok = 0) > 0
begin
	update #health
		set Healthy = 0
	where Metric = 'DBState'
end

else
begin
	update #health
		set Healthy = 1
	where Metric = 'DBState'
end

-- check error log for errors		
-- intialize #health check
		insert into #health (Metric, Healthy) values ('ErrorLogScrape',NULL)

-- load the current error log into a table
insert into #log1
	exec xp_readerrorlog 0,1

-- check for errors since the last startup
insert into #log2
select * from #log1
where LogDate >= @startup
and [Text] like '%suspect%' 
or [Text] like '%replication%' 
or [Text] like '%backup failed%' 
or [Text] like '%EXCEPTION_ACCESS_VIOLATION%' 
or [Text] like '%stack signature%' 
or [Text] like '%error: 926%'
or [Text] like '%error: 822%'
or [Text] like '%SQLServiceControlHandler%' 
or [Text] like '%the handle is invalid%' 
or [Text] like '%could not allocate%' 
or [Text] like '%minimum repair level%'


set @numerror = (select count(*) from #log2)

-- update #health table
if @numerror = 0
begin
	update #health
		set Healthy = 1
	where Metric = 'ErrorLogScrape'
end

else
begin
	update #health
		set Healthy = 0
	where Metric = 'ErrorLogScrape'
end

-- check for missed job runs
-- intialize #health check
		insert into #health (Metric, Healthy) values ('MissedJobs',NULL)

-- create #jobs temp table
create table #jobs (jobname sysname, freq_type int, freq_interval int, freq_subday_type int, freq_subday_interval int, 
					freq_relative_interval int, freq_recurrence_factor int, x_min_sec bit, x_hours bit, daily bit, weekly bit, monthly bit, next_run_datetime datetime, 
					last_run_datetime datetime, minute_since_last_run bigint, missed_run bit);

-- get job details and populate the temp table
with job_cte
as
(
	select 
		j.name,
		j.job_id,
		s.freq_type,
		s.freq_interval,
		s.freq_subday_type,
		s.freq_subday_interval,
		s.freq_relative_interval,
		s.freq_recurrence_factor,
		case when (freq_type = 4 and freq_interval = 1 and freq_subday_type in (2,4)) then 1 else 0 end [x_min_sec],
		case when (freq_type = 4 and freq_interval = 1 and freq_subday_type = 8) then 1 else 0 end [x_hours],
		case when (freq_type = 4 and freq_interval = 1 and freq_subday_type = 1) then 1 
			when (freq_type = 8 and freq_interval & 127 = 127) then 1 else 0 end [daily],
		case when (freq_type = 8 and freq_interval & 127 <> 127) then 1 else 0 end [weekly],
		case when (freq_type = 16) then 1 else 0 end [monthly]
	from msdb.dbo.sysjobs j
	inner join msdb.dbo.sysjobschedules js on j.job_id = js.job_id
	inner join msdb.dbo.sysschedules s on js.schedule_id = s.schedule_id
	inner join msdb.dbo.syscategories c on j.category_id = c.category_id
	where j.enabled = 1
	and c.name like '%@%'
)
insert into #jobs
	select j.name, j.freq_type, j.freq_interval, j.freq_subday_type, j.freq_subday_interval, j.freq_relative_interval, 
		j.freq_recurrence_factor, j.x_min_sec, j.x_hours, j.daily, j.weekly, j.monthly, msdb.dbo.agent_datetime(s.next_run_date,s.next_run_time) [next_run_datetime],
		max(msdb.dbo.agent_datetime(h.run_date,h.run_time)) [last_run_datetime],
		datediff(minute,max(msdb.dbo.agent_datetime(h.run_date,h.run_time)),getdate()) [min_since_last_run],NULL
	from job_cte j
	inner join msdb.dbo.sysjobhistory h on j.job_id = h.job_id
	inner join msdb.dbo.sysjobschedules s on j.job_id = s.job_id
	--where j.x_min_sec = 0 or j.x_hours = 1 and j.freq_subday_interval >= 2
	group by j.name, j.freq_type, j.freq_interval, j.freq_subday_type, j.freq_subday_interval, j.freq_relative_interval, 
		j.freq_recurrence_factor, j.x_min_sec, j.x_hours, j.daily, j.weekly, j.monthly, msdb.dbo.agent_datetime(s.next_run_date,s.next_run_time)

-- parse jobs to see which were missed
declare job_cursor cursor for
	select jobname, freq_subday_type, freq_subday_interval, x_min_sec, x_hours, daily, weekly, monthly, last_run_datetime, minute_since_last_run, next_run_datetime from #jobs

open job_cursor
fetch next from job_cursor into @curjob, @subtype, @subinterval, @xminsec, @xhours, @daily, @weekly, @monthly, @lastrun, @sincelast, @nextrun

while @@FETCH_STATUS = 0
begin
	-- more frequent than every 2 hours
	if (@xminsec = 1 and @subtype in (2,4)) or (@xhours = 1 and @subinterval < 2)
	begin
		set @untilnext =
			case
				when @xminsec = 1 and @subtype = 2 then @subinterval/60
				when @xminsec = 1 and @subtype = 4 then @subinterval
				when @xhours = 1 then @subinterval*60
			end

		if datediff(minute,getdate(),@nextrun) <= @untilnext
		begin
			update #jobs
				set missed_run = 0
			where jobname = @curjob
		end

		else
		begin
			update #jobs
				set missed_run = 1
			where jobname = @curjob
		end
	end
	
	-- hourly but every 2+ hours
	if @xhours = 1 and @subtype = 8 and @subinterval >= 2
	begin
		if datediff(hour,@lastrun,getdate()) > @subinterval
		begin
			update #jobs
				set missed_run = 1
			where jobname = @curjob
		end
		else
		begin
			update #jobs
				set missed_run = 0
			where jobname = @curjob
		end
	end

	-- once a day checks
	if @daily = 1
	begin
		if @sincelast > 1440
		begin
			update #jobs
				set missed_run = 1
			where jobname = @curjob
		end
		else
		begin
			update #jobs
				set missed_run = 0
			where jobname = @curjob
		end
	end

	-- weekly checks

	-- monthly checks

	fetch next from job_cursor into @curjob, @subtype, @subinterval, @xminsec, @xhours, @daily, @weekly, @monthly, @lastrun, @sincelast, @nextrun
end

close job_cursor
deallocate job_cursor

-- see if jobs are healthy
if (select count(*) from #jobs where missed_run = 1) > 0
begin
	update #health
		set Healthy = 0
	where Metric = 'MissedJobs'
end

else
begin
	update #health
		set Healthy = 1
	where Metric = 'MissedJobs'
end


--------------- DEBUG -----------------
--select 'SQL Server started at ' + CAST(@startup as nvarchar(25))
--select * from #jobs
--select * from #dbprop order by dbname
--select * from #repjobs
--select * from #mirrors
--select * from #endpoints
--if OBJECT_ID('tempdb.dbo.#AOAGStatus') is not null select * from #AOAGStatus
select * from #health
--if OBJECT_ID('tempdb.dbo.#logship') is not null select * from #logship
--select * from #log2
---------------------------------------
if (select Healthy from #health where Metric = 'Replication') = 0
begin
	select * from #repjobs
end
if (select Healthy from #health where Metric = 'Mirroring') = 0
begin
	select * from #mirrors
	select * from #endpoints
end
if (select Healthy from #health where Metric = 'LogShipping') = 0
begin
	select * from #logship
end
if (select Healthy from #health where Metric = 'DBState') = 0
begin
	select * from #dbprop
end
if (select Healthy from #health where Metric = 'ErrorLogScrape') = 0
begin
	select * from #log2
end
if (select Healthy from #health where Metric = 'MissedJobs') = 0
begin
	select * from #jobs
	where missed_run = 1
end

-- cleanup
if OBJECT_ID('tempdb.dbo.#dbprop') is not null
	drop table #dbprop
if OBJECT_ID('tempdb.dbo.#repjobs') is not null
	drop table #repjobs
if OBJECT_ID('tempdb.dbo.#log1') is not null
	drop table #log1
if OBJECT_ID('tempdb.dbo.#log2') is not null
	drop table #log2
if OBJECT_ID('tempdb.dbo.#health') is not null
	drop table #health
if OBJECT_ID('tempdb.dbo.#mirrors') is not null
	drop table #mirrors
if OBJECT_ID('tempdb.dbo.#endpoints') is not null
	drop table #endpoints
if OBJECT_ID('tempdb.dbo.#AOAGStatus') is not null
	drop table #AOAGStatus
if OBJECT_ID('tempdb.dbo.#logship') is not null
	drop table #logship
if OBJECT_ID('tempdb.dbo.#jobs') is not null
	drop table #jobs