--run sp_who2 order by Block By column

declare @T table
(
	SPID int,
	Status varchar(100),
	[Login] varchar(100),
	HostName varchar(100),
	BlkBy varchar(100),
	DBName varchar(100),
	Command varchar(100),
	CPUTIME varchar(100),
	DISKIO varchar(100),
	LASTBATCH varchar(100),
	PROGRAMNAME varchar(100),
	SPID1 varchar(100),
	REQUESTID varchar(100)	
)
insert into @T 
exec('sp_who2')
select * from @T
order by BlkBy
