--Used to check job status of RDS job
CREATE FUNCTION dbo.SqlAgentJob_GetStatus (@JobName sysname)
    RETURNS TABLE
AS
RETURN
SELECT TOP 1
    JobName        = j.name,
    IsRunning      = CASE
                       WHEN ja.job_id IS NOT NULL
                           AND ja.stop_execution_date IS NULL
                         THEN 1 ELSE 0 
                       END,
    RequestSource  = ja.run_requested_source,
    LastRunTime    = ja.start_execution_date,
    NextRunTime    = ja.next_scheduled_run_date,
    LastJobStep    = js.step_name,
    RetryAttempt   = jh.retries_attempted,
    JobLastOutcome = CASE
                       WHEN ja.job_id IS NOT NULL
                           AND ja.stop_execution_date IS NULL THEN 'Running'
                       WHEN jh.run_status = 0 THEN 'Failed'
                       WHEN jh.run_status = 1 THEN 'Succeeded'
                       WHEN jh.run_status = 2 THEN 'Retry'
                       WHEN jh.run_status = 3 THEN 'Cancelled'
                     END
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobactivity ja 
    ON ja.job_id = j.job_id
       AND ja.run_requested_date IS NOT NULL
       AND ja.start_execution_date IS NOT NULL
LEFT JOIN msdb.dbo.sysjobsteps js
    ON js.job_id = ja.job_id
       AND js.step_id = ja.last_executed_step_id
LEFT JOIN msdb.dbo.sysjobhistory jh
    ON jh.job_id = j.job_id
       AND jh.instance_id = ja.job_history_id
WHERE j.name = @JobName
ORDER BY ja.start_execution_date DESC;
GO


CREATE PROCEDURE dbo.sp_sp_start_job_wait
(
@job_name SYSNAME,
@WaitTime DATETIME = '00:00:05', -- this is parameter for check frequency
@JobCompletionStatus INT = null OUTPUT
)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

-- DECLARE @job_name sysname
DECLARE @job_id UNIQUEIDENTIFIER
DECLARE @job_owner sysname

--Createing TEMP TABLE
CREATE TABLE #xp_results (JobName varchar(1000),
IsRunning int,
RequestSource int,
LastRunTime datetime,
NextRunTime datetime,
LastJobStep varchar(1000),
RetryAttempt int,
JobLastOutcome varchar(1000)
)

--SELECT @job_id = job_id FROM msdb.dbo.sysjobs
--WHERE name = @job_name

--SELECT @job_owner = SUSER_SNAME()

INSERT INTO #xp_results
select * from SqlAgentJob_GetStatus (@job_name)
--EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, @job_owner, @job_id

-- Start the job if the job is not running
IF NOT EXISTS(SELECT TOP 1 * FROM #xp_results WHERE IsRunning = 1)
EXEC msdb.dbo.sp_start_job @job_name = @job_name

-- Give 2 sec for think time.
WAITFOR DELAY '00:00:02'

DELETE FROM #xp_results
INSERT INTO #xp_results
select * from SqlAgentJob_GetStatus (@job_name)
--EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, @job_owner, @job_id


WHILE EXISTS(SELECT TOP 1 * FROM #xp_results WHERE IsRunning = 1)
BEGIN

WAITFOR DELAY @WaitTime

-- Information
raiserror('JOB IS RUNNING', 0, 1 ) WITH NOWAIT

DELETE FROM #xp_results

INSERT INTO #xp_results
select * from SqlAgentJob_GetStatus (@job_name)
--EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, @job_owner, @job_id

END

SELECT top 1 @JobCompletionStatus = run_status
FROM msdb.dbo.sysjobhistory
WHERE job_id = @job_id
and step_id = 0
order by run_date desc, run_time desc

IF @JobCompletionStatus = 1
PRINT 'The job ran Successful'
ELSE IF @JobCompletionStatus = 3
PRINT 'The job is Cancelled'
ELSE
BEGIN
RAISERROR ('[ERROR]:%s job is either failed or not in good state. Please check',16, 1, @job_name) WITH LOG
END

RETURN @JobCompletionStatus

GO