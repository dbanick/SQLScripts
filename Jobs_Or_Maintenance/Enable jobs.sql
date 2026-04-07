-- Updated 6/25/14 


USE [msdb]
DECLARE @id uniqueidentifier
declare dbcursor CURSOR for 
	SELECT job_id from msdb.dbo.sysjobs 
Open dbcursor

Fetch next from dbcursor into @id

	WHILE @@FETCH_STATUS = 0
		BEGIN 
			EXEC msdb.dbo.sp_update_job @job_id=@id, @enabled=1
	
			Fetch next from dbcursor into @id
		END
      
CLOSE dbcursor
DEALLOCATE dbcursor
go
