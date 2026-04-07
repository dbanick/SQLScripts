--this will create a table named dbaBlockProc
--it will run every second and recod any blocking information it finds
--it is set to run repeatedly in a loop for 3600 seconds, and purges blocking information over 2 weeks old
--designed around SQL 2005


use master
go
if not exists (select name from master.sys.sysobjects where name ='dbaBlockProc')
	Begin
		create table master..dbaBlockProc
		(
			[Date] datetime,
			Blocked_Session_ID int,
			Blocked_SQL varchar(max),
			Blocked_resource nvarchar(60) null,
			wait_resource nvarchar(512) null,
			Blocking_Session_ID int,
			Blocking_SQL varchar(max),
		)
	End

declare @intv int

set @intv = 3600
while @intv > 0
	Begin
		If (select count(*) from sysprocesses a, sysprocesses b where a.spid<> b.blocked and a.blocked <> 0) > 0
			Begin

				insert into dbaBlockProc
				select GETDATE(),
				Blocked.session_id as Blocked_Session_ID,
				Blocked_SQL.text as Blocked_SQL,
				waits.wait_type as Blocked_resource,
				Blocked.wait_resource as wait_resource,
				Blocking.session_id as Blocking_Session_ID,
				Blocking_SQL.text as Blocking_SQL
				

				from sys.dm_exec_connections as Blocking
				inner join sys.dm_exec_requests as Blocked
					on Blocked.blocking_session_id = Blocking.session_id
				cross apply
					(
						select * from sys.dm_exec_sql_text(Blocking.most_recent_sql_handle)
					) as Blocking_SQL
				Cross apply
					(
						select * from sys.dm_exec_sql_text(Blocked.sql_handle)
					) as Blocked_SQL
				inner join sys.dm_os_waiting_tasks as waits
					on waits.session_id=Blocked.session_id
				 
			End
		delete from dbablockproc where [Date] <= dateadd(dd, -14, getdate() ) 
		--select @intv
		waitfor delay '00:00:01'
		--set @intv = @intv-1
	End
select * from master..dbaBlockProc
go