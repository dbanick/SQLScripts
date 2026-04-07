create table #login
(logdate datetime, processinfo varchar(100), [message] varchar(1000))
insert into #login EXEC sp_readerrorlog 0, 1, 'Login failed' 
insert into #login EXEC sp_readerrorlog 1, 1, 'Login failed' 
insert into #login EXEC sp_readerrorlog 2, 1, 'Login failed' 
insert into #login EXEC sp_readerrorlog 3, 1, 'Login failed' 
insert into #login EXEC sp_readerrorlog 4, 1, 'Login failed' 
insert into #login EXEC sp_readerrorlog 5, 1, 'Login failed' 



--select * from #login


select logdate,
SUBSTRING(
	message, 
	PATINDEX( '%Login failed %', message)+23, 
	(PATINDEX( '%. Reason%', message)-1) - (PATINDEX( '%Login failed %', message)+23)) as [loginName],
	SUBSTRING(message, PATINDEX( '%CLIENT: %', message)+8, LEN(message) - (PATINDEX( '%CLIENT: %', message)+8)) as [HostName],
	message
from #login
where (PATINDEX( '%. Reason%', message)-1) - (PATINDEX( '%Login failed %', message)+23) > 0


;WITH CTE as (
SELECT
SUBSTRING(
	message, 
	PATINDEX( '%Login failed %', message)+23, 
	(PATINDEX( '%. Reason%', message)-1) - (PATINDEX( '%Login failed %', message)+23)) as [loginName],
	SUBSTRING(message, PATINDEX( '%CLIENT: %', message)+8, LEN(message) - (PATINDEX( '%CLIENT: %', message)+8)) as [HostName]
	from #login
where (PATINDEX( '%. Reason%', message)-1) - (PATINDEX( '%Login failed %', message)+23) > 0
)
select loginName, hostname, COUNT(1) as [count] from CTE group by loginName, hostname order by 3 desc

drop table #login