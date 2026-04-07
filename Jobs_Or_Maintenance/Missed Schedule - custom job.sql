declare @job varchar(50)
declare @min int
declare @jobmin int
declare @body varchar(250)
declare @subject varchar(100)
declare @lastrun datetime
declare @nextrun datetime

--job to monitor and schedule interval
set @job = 'Job Name'
set @min = 15

select @lastrun = ja.run_requested_date from msdb..sysjobactivity ja
inner join msdb..sysjobs sj on ja.job_id = sj.job_id
where sj.name = @job

select @nextrun = ja.next_scheduled_run_date from msdb..sysjobactivity ja
inner join msdb..sysjobs sj on ja.job_id = sj.job_id
where sj.name = @job

--find time elapsed since last execution
select @jobmin = DATEDIFF(mi, MAX(msdb.dbo.agent_datetime(run_date, run_time)), getdate())
FROM msdb.dbo.sysjobs sj
inner JOIN msdb.dbo.sysjobhistory sjh ON sj.job_id = sjh.job_id
WHERE sjh.step_id = 0
and sj.name = @job
GROUP BY sj.name

--if elapsed time exceeds schedule email on possible missed execution
if @jobmin > @min
begin
set @subject = @job + ' Missed Schedule'
set @body = @job + ' job has missed a scheduled execution. It has not executed in over ' + cast(@min as varchar) + ' minutes. 
The last run was ' + cast(@lastrun as varchar) + '. The next run is ' + cast(@nextrun as varchar) + '. Please investigate.'


Execute as login='sa'
   EXEC msdb..sp_send_dbmail
	@profile_name = 'Default Profile',
	@recipients = 'jwasher@rdx.com',
	@subject = @subject,
	@body = @body

end
else
print 'Under Threshold'