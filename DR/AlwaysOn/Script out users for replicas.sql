--Find and replace following:
--AG name '811612-SQLAG'
--Partner name '809477-db3'

--create table if it doesn't exist
IF Object_Id('master..logins') IS NULL
BEGIN
		CREATE TABLE logins
		(
		loginId int IDENTITY(1, 1) NOT NULL,
		loginName nvarchar(128) NOT NULL,
		passwordHash varbinary(256) NULL,
		[sid] varbinary(85) NOT NULL,
		type_desc varchar(100),
		isApplied bit DEFAULT 0
		)
END

--Only repopulate the table if the server is the secondary AND if you can connect to primary
if (select
        ars.role_desc
    from sys.dm_hadr_availability_replica_states ars
    inner join sys.availability_groups ag
    on ars.group_id = ag.group_id
    where ag.name = '811612-SQLAG'
    and ars.is_local = 1) != 'PRIMARY'
	AND (SELECT count(1)	FROM OPENQUERY([809477-db3], 'select @@servername')) > 0
begin
	select 'cleaning up logins table to reload'
	Truncate table logins
	-- openquery is used so that loginproperty function runs on the remote server, otherwise we get back null
	INSERT INTO logins(loginName, passwordHash, [sid], type_desc, isApplied)
	SELECT *
	FROM OPENQUERY([809477-db3], '
		SELECT [name]
		,CONVERT(varbinary(256), LOGINPROPERTY(name, ''PasswordHash''))
		,[sid]
		,type_desc
		,0
		FROM
		master.sys.server_principals
		where
		name NOT IN (''sa'', ''guest'') and
		[name] not like ''sa%''
		ORDER BY name
		')

	--mark the system IDs as already having been created
	Update logins set isApplied = 1 where loginName like '#%' or loginName like 'NT Service%' 
END

	--debug
	select * from logins where isApplied = 0


	DECLARE 
	@count int
	,@loginId int
	,@loginName nvarchar(128)
	,@passwordHashOld varbinary(256)
	,@passwordHashNew varbinary(256)
	,@sid varbinary(85)
	,@sql nvarchar(4000)
	,@password varchar(514)
	,@sidplain varchar(514)
	,@type_desc varchar(100)


--Run this next section of code if server is the primary
--
if (select
        ars.role_desc
    from sys.dm_hadr_availability_replica_states ars
    inner join sys.availability_groups ag
    on ars.group_id = ag.group_id
    where ag.name = '811612-SQLAG'
    and ars.is_local = 1) = 'PRIMARY'
begin

	declare LoginCursor CURSOR for SELECT loginID, loginName, passwordHash, [sid], type_desc from logins where isApplied = 0
	Open LoginCursor

	Fetch next from LoginCursor
	into @loginID, @loginName, @passwordHashNew, @sid, @type_Desc

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- if the account doesn't exist, then we need to create it
		IF NOT EXISTS (SELECT * FROM master.sys.server_principals WHERE name = @loginName)
		BEGIN
			EXEC master.dbo.sp_hexadecimal @passwordHashNew, @password OUTPUT
			EXEC master.dbo.sp_hexadecimal @sid, @sidplain OUTPUT

			SET @sql = 	case
			when @type_desc = 'SQL_LOGIN' 
				then 'CREATE LOGIN ' + @loginName + ' WITH PASSWORD = ' + 
					CONVERT(nvarchar(512), COALESCE(@password, 'NULL')) + ' HASHED, SID = ' + CONVERT(nvarchar(512), 
					COALESCE(@sidplain, 'NULL')) + ', CHECK_POLICY = OFF' 
			when @type_desc IN ( 'WINDOWS_GROUP', 'WINDOWS_LOGIN' ) 
				then 'CREATE LOGIN [' + @loginName + '] FROM WINDOWS WITH DEFAULT_DATABASE=[master]'
			else 'print ''This is not a SQL or Windows user, skipping'''
		END

		PRINT @sql
		EXEC (@sql)

		PRINT 'login created'
		Update logins set isApplied = 1 where loginID = @loginID --mark the ID as already having been created

		END


	-- if the account does exist, then we need to drop/create; can't alter as hashed isn't supported
	ELSE
		BEGIN
			SELECT @passwordHashOld = CONVERT(varbinary(256), LOGINPROPERTY(@loginName, 'PasswordHash'))
			print 'Working on login: ' + @loginName
			IF @passwordHashOld <> @passwordHashNew
				BEGIN
					EXEC master.dbo.sp_hexadecimal @passwordHashNew, @password OUTPUT
					EXEC master.dbo.sp_hexadecimal @sid, @sidplain OUTPUT

					SET @sql = 'DROP LOGIN ' + @loginName
					EXEC (@sql)
					PRINT (@sql)

					SET @sql = 'CREATE LOGIN ' + @loginName + ' WITH PASSWORD = ' + CONVERT(nvarchar(512), 						COALESCE(@password, 'NULL')) + ' HASHED, SID = ' + CONVERT(nvarchar(512), 						COALESCE(@sidplain, 'NULL')) + ', CHECK_POLICY = OFF' 
					EXEC (@sql)
					PRINT (@sql)

					PRINT 'login "altered"'
				END
			else
				begin
					PRINT 'login "' + @loginName + '" exists with proper password'
				end
		END

		
	Update logins set isApplied = 1 where loginID = @loginID --mark the ID as already having been created
	Fetch next from LoginCursor
	into @loginID, @loginName, @passwordHashNew, @sid, @type_Desc	
	
	END

	CLOSE LoginCursor
	DEALLOCATE LoginCursor	
END

GO
--debug
select * from logins --where isApplied = 0