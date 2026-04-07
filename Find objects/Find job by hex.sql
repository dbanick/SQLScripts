DECLARE @JobName varchar(max)
SELECT @JobName = [name]
FROM msdb.dbo.sysjobs
WHERE job_id = cast(0xFF11A8EB8809AC4199B9D07BDFAFB5A8 AS uniqueidentifier)
EXECUTE
msdb..sp_help_job @job_name = @JobName
EXECUTE
msdb..sp_help_jobstep @job_name = @JobName