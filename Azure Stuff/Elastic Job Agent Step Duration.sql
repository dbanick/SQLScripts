use [data-admin]
SELECT 
j.name, 
s.step_name,
s.step_id,
je.lifecycle,
je.[start_time],
je.[end_time],
DATEDIFF(minute, cast(je.[start_time] as time), cast(je.[end_time] as time)) as [Duration_Minutes]
  FROM [jobs_internal].[job_executions] je
  join [jobs_internal].[jobs] j
  on j.job_id = je.job_id
  join [jobs_internal].[jobsteps] s 
  on j.job_id = s.job_id and je.step_id = s.step_id and je.job_version_number = s.job_version_number
  where je.start_time > getdate()-30
  --and j.name = 'NightlyTasks'
 --and s.step_name = 'RunISSAAging_MostRecentPayments'
order by name, step_id

