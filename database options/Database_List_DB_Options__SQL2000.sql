--******This script is for versions before 2012***********

--getting db info
create table #dbdata (
	dbid int null,
	db varchar(30) null,
	options varchar(300) null)

declare @dbid int,
	@dbname varchar(30),
	@dbsize float,
	@datasize float,
	@logsize float,
	@list varchar (300),
	@temp varchar (100)
declare dbcursor CURSOR for select dbid,db from #dbdata

INSERT #dbdata (dbid,db)
select dbid,cast(name as varchar(30)) from master..sysdatabases

Open dbcursor

Fetch next from dbcursor
into @dbid,@dbname

WHILE @@FETCH_STATUS = 0
BEGIN 
	create table #temp(
	options varchar(50)
	)

	declare optioncursor CURSOR for select options from #temp

	INSERT into #temp
	EXEC sp_dboption @dbname

	Open optioncursor

	Fetch next from optioncursor
	into @temp
	select @list = ' '
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		if @list = ' '
			select @list = RTRIM(@temp)
		else
			select @list = @list + ',' + RTRIM(@temp)

		Fetch next from optioncursor
		into @temp
	END

	update #dbdata
	set options = @list
	where db = @dbname
	
	drop table #temp
	CLOSE optioncursor
	DEALLOCATE optioncursor

Fetch next from dbcursor
into @dbid,@dbname

END
	
select db, options from #dbdata order by db
drop table #dbdata
CLOSE dbcursor
DEALLOCATE dbcursor