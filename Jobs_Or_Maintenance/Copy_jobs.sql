--These scripts will generate insert commands to copy existing jobs from one server to another. 
---This is similar to the dbatools function, but used in cases where dbatools cannot be used; for example, it was developed for a server with over 4000 jobs that would time out with dbatools
--adjust the filters appropriately

select
'insert into sysschedules (schedule_id, schedule_uid, originating_server_id, name, owner_sid, enabled, freq_type, freq_interval, freq_subday_type, freq_subday_interval, freq_relative_interval, freq_recurrence_factor, active_start_date, active_end_date, active_start_time, active_end_time, date_created, date_modified, version_number)
select ''' + cast(schedule_id as varchar(500))+ ''',''' +  cast(schedule_uid as varchar(500)) + ''',''' +  cast(originating_server_id as varchar(500)) + ''',''' 
+  cast(name  as varchar(500))+ ''',''' +  cast('0xB0BB4898385C3543997510BCDE5AB919' as varchar(500)) + ''',''' +  cast(enabled  as varchar(500))+ ''',''' +  cast(freq_type as varchar(500)) + ''',''' +  
cast(freq_interval  as varchar(500))+ ''',''' +  cast(freq_subday_type as varchar(500)) + ''',''' +  cast(freq_subday_interval  as varchar(500))+ ''',''' +  
cast(freq_relative_interval as varchar(500)) + ''',''' +  cast(freq_recurrence_factor  as varchar(500))+ ''',''' +  cast(active_start_date  as varchar(500))
+ ''',''' +  cast(active_end_date  as varchar(500))+ ''',''' +  cast(active_start_time  as varchar(500))+ ''',''' +  cast(active_end_time as varchar(500)) + ''',''' 
+  cast(date_created  as varchar(500))+ ''',''' +  cast(date_modified  as varchar(500))+ ''',''' +  cast(version_number  as varchar(500))+ ''''
, * from sysschedules
where schedule_id in (
 select s.schedule_id from sysjobschedules s
join sysjobs j on s.job_id = j.job_id
where j.name  like 'ATXT%'
or j.name like 'AUTO%'
or j.name like 'WCT3HH%'
or j.name like 'WPAATB3H%'
or j.name like 'WPAZB43H%'
or j.name like 'ZCT3HH%'
or j.name like 'ZFPKEYNE%'
or j.name like 'ZFPKEYNY%'
or j.name like 'ZSADHH%'
or j.name like 'ZSAHHH%'
or j.name like 'BLM%'
and j.name not like 'autoupdate%'
)



use msdb
select s.* , 
'insert into sysjobschedules select ''' 
+ cast(s.schedule_id   as varchar(500))+ ''',''' 
+ cast(s.job_id  as varchar(500)) +  ''',''' 
+ cast(s.next_run_date  as varchar(500))  + ''',''' 
+ cast(s.next_run_time as varchar(500)) + ''''
from sysjobschedules s
join sysjobs j on s.job_id = j.job_id
where j.name  like 'ATXT%'
or j.name like 'AUTO%'
or j.name like 'WCT3HH%'
or j.name like 'WPAATB3H%'
or j.name like 'WPAZB43H%'
or j.name like 'ZCT3HH%'
or j.name like 'ZFPKEYNE%'
or j.name like 'ZFPKEYNY%'
or j.name like 'ZSADHH%'
or j.name like 'ZSAHHH%'
or j.name like 'BLM%'
and j.name not like 'autoupdate%'






select
'insert into sysjobsteps (job_id, step_id, step_name, subsystem, command, flags, additional_parameters, cmdexec_success_code, on_success_action, on_success_step_id, on_fail_action, on_fail_step_id, server, database_name, database_user_name, retry_attempts, retry_interval, os_run_priority, output_file_name, last_run_outcome, last_run_duration, last_run_retries, last_run_date, last_run_time, proxy_id, step_uid)
select ''' + cast(s.job_id as varchar(2000)) + ''',''' 
+ cast(s.step_id as varchar(2000)) + ''',''' 
+ cast(s.step_name as varchar(2000)) + ''',''' 
+ cast(s.subsystem as varchar(2000)) + ''',''' 
+ cast(s.command as nvarchar(max)) + ''',''' 
+ cast(s.flags as varchar(2000)) + ''',''' 
+ cast(s.additional_parameters as varchar(2000)) + ''',''' 
+ cast(s.cmdexec_success_code as varchar(2000)) + ''',''' 
+ cast(s.on_success_action as varchar(2000)) + ''',''' 
+ cast(s.on_success_step_id as varchar(2000)) + ''',''' 
+ cast(s.on_fail_action as varchar(2000)) + ''',''' 
+ cast(s.on_fail_step_id as varchar(2000)) + ''',''' 
+ cast(s.server as varchar(2000)) + ''',''' 
+ cast(s.database_name as varchar(2000)) + ''',''' 
+ cast(s.database_user_name as varchar(2000)) + ''',''' 
+ cast(s.retry_attempts as varchar(2000)) + ''',''' 
+ cast(s.retry_interval as varchar(2000)) + ''',''' 
+ cast(s.os_run_priority as varchar(2000)) + ''',''' 
+ cast(s.output_file_name as varchar(2000)) + ''',''' 
+ cast(s.last_run_outcome as varchar(2000)) + ''',''' 
+ cast(s.last_run_duration as varchar(2000)) + ''',''' 
+ cast(s.last_run_retries as varchar(2000)) + ''',''' 
+ cast(s.last_run_date as varchar(2000)) + ''','''
 + cast(s.last_run_time as varchar(2000)) + ''',''' 
+ cast(s.proxy_id as varchar(2000)) + ''',''' 
+ cast(s.step_uid as varchar(2000)) + ''''

, s.* 
from sysjobsteps s
join sysjobs j on s.job_id = j.job_id
where j.name  like 'ATXT%'
or j.name like 'AUTO%'
or j.name like 'WCT3HH%'
or j.name like 'WPAATB3H%'
or j.name like 'WPAZB43H%'
or j.name like 'ZCT3HH%'
or j.name like 'ZFPKEYNE%'
or j.name like 'ZFPKEYNY%'
or j.name like 'ZSADHH%'
or j.name like 'ZSAHHH%'
or j.name like 'BLM%'
and j.name not like 'autoupdate%'














select
'insert into sysjobsteps (job_id, step_id, step_name, subsystem, command, flags, 
cmdexec_success_code, on_success_action, on_success_step_id, on_fail_action, on_fail_step_id, 
database_name,  retry_attempts, retry_interval, os_run_priority,  
last_run_outcome, last_run_duration, last_run_retries, last_run_date, last_run_time,  step_uid)
select ''' + cast(s.job_id as varchar(200)) + ''',''' 
+ cast(s.step_id as varchar(2000)) + ''',''' 
+ cast(s.step_name as varchar(2000)) + ''',''' 
+ cast(s.subsystem as varchar(2000)) + ''',''' 

,cast(replace(s.command, '''', '''''') as nvarchar(max)) + ''',''' 
, cast(s.flags as varchar(2000)) + ''',''' 
--, cast(coalesce(s.additional_parameters, 'null') as ntext) 
+ cast(s.cmdexec_success_code as varchar(2000)) + ''',''' 
+ cast(coalesce(s.on_success_action, NULL) as varchar(2000)) + ''',''' 
+ cast(s.on_success_step_id as varchar(2000)) + ''',''' 
+ cast(s.on_fail_action as varchar(2000)) + ''',''' 
+ cast(s.on_fail_step_id as varchar(2000)) + ''',''' 
--+ cast(s.server as varchar(2000)) + ''',''' 
+ cast(s.database_name as varchar(2000)) + ''',''' 
--+ cast(s.database_user_name as varchar(2000)) + ''',''' 
+ cast(s.retry_attempts as varchar(2000)) + ''',''' 
+ cast(s.retry_interval as varchar(2000)) + ''',''' 
+ cast(s.os_run_priority as varchar(2000)) + ''',''' 
--+ cast(s.output_file_name as varchar(2000)) + ''',''' 
+ cast(s.last_run_outcome as varchar(2000)) + ''',''' 
+ cast(s.last_run_duration as varchar(2000)) + ''',''' 
+ cast(s.last_run_retries as varchar(2000)) + ''',''' 
+ cast(s.last_run_date as varchar(2000)) + ''','''
 + cast(s.last_run_time as varchar(2000)) + ''',''' 
--+ cast(s.proxy_id as varchar(2000)) + ''',''' 
+ cast(s.step_uid as varchar(2000)) + ''''

, s.* 
from sysjobsteps s
join sysjobs j on s.job_id = j.job_id
where j.name  like 'ATXT%'
or j.name like 'AUTO%'
or j.name like 'WCT3HH%'
or j.name like 'WPAATB3H%'
or j.name like 'WPAZB43H%'
or j.name like 'ZCT3HH%'
or j.name like 'ZFPKEYNE%'
or j.name like 'ZFPKEYNY%'
or j.name like 'ZSADHH%'
or j.name like 'ZSAHHH%'
or j.name like 'BLM%'
and j.name not like 'autoupdate%'

