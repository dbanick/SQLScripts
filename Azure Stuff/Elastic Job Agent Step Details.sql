use [data-admin]
SELECT 
j.name, 
j.description, 
s.step_name,
s.step_id,
s.job_version_number,
sb.[command_text]
  FROM [jobs_internal].[jobs] j
  join [jobs_internal].[jobsteps] s 
  on j.job_id = s.job_id
  join [jobs_internal].[jobstep_data] jd 
  on s.jobstep_data_id = jd.jobstep_data_id
  join [jobs_internal].[script_batches] sb
  on jd.command_data_id = sb.command_data_id
  join (
  select jj.job_id, max(jj.job_version_number) as job_version_number from  [jobs_internal].[jobsteps] jj
  group by jj.job_id
  ) a on a.job_version_number = s.job_version_number and a.job_id = s.job_id
  --where j.name = 'NightlyTasks'
  order by name, step_id