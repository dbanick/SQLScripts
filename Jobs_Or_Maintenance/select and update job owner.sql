/* Run query to find jobs owned by a specific login */

select j.name as job, SUSER_SNAME(j.owner_sid) from msdb.dbo.sysjobs j
WHERE SUSER_SNAME(j.owner_sid) = 'login'



/* Run below to change the job owner of all jobs owned by a specific login to sa */

DECLARE @id uniqueidentifier
declare dbcursor CURSOR for
select job_id from msdb.dbo.sysjobs j
WHERE SUSER_SNAME(j.owner_sid) = 'login'


Open dbcursor

Fetch next from dbcursor
into @id

WHILE @@FETCH_STATUS = 0
BEGIN
SELECT 'EXEC msdb.dbo.sp_update_job @job_id=@id, @owner_login_name=N''sa'''
EXEC msdb.dbo.sp_update_job @job_id=@id, @owner_login_name=N'sa'

Fetch next from dbcursor into @id
END
CLOSE dbcursor
DEALLOCATE dbcursor
go
