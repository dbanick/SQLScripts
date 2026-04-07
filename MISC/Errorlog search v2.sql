declare @startdate datetime,
@enddate datetime

set @startdate = DATEADD(DAY,-1, GETDATE())
set @enddate = GETDATE()

create table #rdxerrorlog (LogDate datetime, ProcessInfo varchar(25), Text varchar(max))

insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
EXEC master.dbo.xp_readerrorlog 0, 1, null, null, @startdate, @enddate, "desc"

IF EXISTS (select [text] from #rdxerrorlog where [text] like 'SQL Server is starting%' OR [text] like 'The error log has been reinitialized%')
 BEGIN
  insert into #rdxerrorlog (Logdate, ProcessInfo, Text)
  EXEC master.dbo.xp_readerrorlog 1, 1, null, null, @startdate, @enddate, "desc"
 END
select * from #rdxerrorlog
where Text like 'Backup failed%'
or Text like 'Login failed%'
or Text like 'A significant part of sql server memory has been paged out%'
or Text like 'A significant part of sql server process memory has been paged out%'
or Text like '%Stack Signature%'
or Text like '%SUSPECT%'
or Text like 'Could not allocate%'
or Text like 'Autogrow of file%'
or Text like 'Replication%'
or Text like '%I/O requests taking longer than 15 seconds%'
or Text like 'Disallowing page allocations for database%'
or Text like 'The transaction log for database%'
or Text like 'The operating system returned error%'
or Text like 'SQL Server is Starting%'
or Text like 'The error log has been reinitialized%'
order by 2;

drop table #rdxerrorlog