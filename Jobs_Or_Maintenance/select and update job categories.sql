--Run this query to find all jobs that are not a certain cateogory
--in this example, select all jobs that are not db@maint

select j.name as job, c.name as category from msdb.dbo.sysjobs j
INNER JOIN MSDB.dbo.syscategories c ON j.category_id = c.category_id
WHERE c.[Name] != 'db@maint'
order by category


--Run the following to update all jobs that are not one category
--This example finds all jobs that are not db@maint category and
--changes the category to db@warn

DECLARE @id uniqueidentifier
declare dbcursor CURSOR for
select job_id from msdb.dbo.sysjobs j
INNER JOIN MSDB.dbo.syscategories c ON j.category_id = c.category_id
WHERE c.[Name] != 'db@maint'


Open dbcursor

Fetch next from dbcursor
into @id

WHILE @@FETCH_STATUS = 0
BEGIN
SELECT 'EXEC msdb.dbo.sp_update_job @job_id=@id, @category_name=N''db@warn'''
EXEC msdb.dbo.sp_update_job @job_id=@id, @category_name=N'db@warn'

Fetch next from dbcursor into @id
END
CLOSE dbcursor
DEALLOCATE dbcursor
go
