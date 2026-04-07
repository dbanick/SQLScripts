DECLARE @dbname varchar(255)
,@command varchar(1000)

declare dbcursor CURSOR for SELECT name FROM sys.databases
where state_desc = 'ONLINE'
and recovery_model_desc = 'FULL'
--and name not in ('model')
Open dbcursor

Fetch next from dbcursor
into @dbname

WHILE @@FETCH_STATUS = 0
	BEGIN
	set @command = 'ALTER DATABASE [' + @dbname +']' + ' SET RECOVERY SIMPLE WITH NO_WAIT'
	EXEC (@command)
	Fetch next from dbcursor
	into @dbname
END 