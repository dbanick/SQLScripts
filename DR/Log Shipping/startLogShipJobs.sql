DECLARE @job_id UNIQUEIDENTIFIER;

DECLARE job_cursor CURSOR FOR
SELECT job_id
FROM msdb.dbo.sysjobs
WHERE name LIKE 'LS%';

OPEN job_cursor;
FETCH NEXT FROM job_cursor INTO @job_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_start_job @job_id = @job_id;
    FETCH NEXT FROM job_cursor INTO @job_id;
END

CLOSE job_cursor;
DEALLOCATE job_cursor;