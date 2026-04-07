declare @startdate datetime,
@enddate datetime

set @startdate = DATEADD(HOUR,-24, GETDATE())
set @enddate = GETDATE()


create table #rdxerrorlog (LogDate datetime, ProcessInfo varchar(25), Text varchar(max))

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "Backup failed", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "Login failed", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "A significant part of sql server memory has been paged out", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "A significant part of sql server process memory has been paged out", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "Stack Signature", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "SUSPECT", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "Could not allocate", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "Autogrow of file", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "Replication", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "I/O requests taking longer than 15 seconds", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "Disallowing page allocations for database", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 1, 1, "The transaction log for database", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "SQL Server is Starting", null, @startdate, @enddate, "desc"

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, "The error log has been reinitialized", null, @startdate, @enddate, "desc"

IF EXISTS (select [text] from #rdxerrorlog where [text] like 'SQL Server is starting%' OR [text] like 'The error log has been reinitialized%')
	BEGIN
		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "Backup failed", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "Login failed", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "A significant part of sql server memory has been paged out", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "A significant part of sql server process memory has been paged out", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "Stack Signature", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "SUSPECT", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "Could not allocate", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "Autogrow of file", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "Replication", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "I/O requests taking longer than 15 seconds", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "Disallowing page allocations for database", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "The transaction log for database", null, @startdate, @enddate, "desc"

		insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
		EXEC master.dbo.xp_readerrorlog 1, 1, "SQL Server is Starting", null, @startdate, @enddate, "desc"

	END

--SELECT @@SERVERNAME, * from #rdxerrorlog
--order by LogDate desc

if exists (select 1 from #rdxerrorlog)
BEGIN
	select @@SERVERNAME as ServerName, Text, processinfo as type, count(*) as count , GETDATE() as collection_time
	from #rdxerrorlog
	group by Text, processinfo
	order by count desc
END
ELSE 
	select @@SERVERNAME as ServerName, 'No Errors', 'Healthy', 1, getdate()

drop table #rdxerrorlog

/*
Backup failed
Login failed
A significant part of sql server memory has been paged out
A significant part of sql server process memory has been paged out
Stack Signature
SUSPECT
Could not allocate
Autogrow of file
Replication
I/O requests taking longer than 15 seconds
Disallowing page allocations for database
*/
