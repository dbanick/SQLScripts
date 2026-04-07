use msdb
select j.name as [job_name], s.step_id, s.step_name, s.subsystem, s.command, s.database_name, 
s.last_run_date, s.last_run_time from sysjobsteps s
inner join sysjobs j on j.job_id = s.job_id
where --s.database_name = 'ProwACM'
s.last_run_Date >= 20110925
and s.command like '%HstBucketAmount%'
order by 1, 2


use msdb
select j.name as [job_name], s.step_id, s.step_name, s.subsystem, s.command, s.database_name, 
s.last_run_date, s.last_run_time from sysjobsteps s
inner join sysjobs j on j.job_id = s.job_id
where s.command like '%HstBucketAmount%'
order by 1, 2