--Find and replace following:
--AG name 'WHSQLAG'
--Partner name 'WHSQLWR1'

--build variables
DECLARE @cmd varchar(max)
DECLARE @SERVERROLE VARCHAR(100)
DECLARE @MEMBERNAME VARCHAR(100) 
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
IF Object_Id('master..login_roles') IS NULL
BEGIN
		CREATE TABLE login_roles
		(
		loginId int IDENTITY(1, 1) NOT NULL,
		serverRole nvarchar(128) NOT NULL,
		memberName nvarchar(128) NULL,
		[sid] varbinary(85) NOT NULL,
		isApplied bit DEFAULT 0
		)
END

--Only repopulate the table if the server is the secondary AND if you can connect to primary
if (select
        ars.role_desc
    from sys.dm_hadr_availability_replica_states ars
    inner join sys.availability_groups ag
    on ars.group_id = ag.group_id
    where ag.name = 'WHSQLAG'
    and ars.is_local = 1) != 'PRIMARY'
	AND (SELECT count(1)	FROM OPENQUERY([WHSQLWR1], 'select @@servername')) > 0
begin
	--debug
	--select 'cleaning up logins tables to reload'
	
	Truncate table logins
	Truncate table login_roles

	-- openquery is used so that loginproperty function runs on the remote server, otherwise we get back null
	-- grab all logins and their hashed password
	INSERT INTO logins(loginName, passwordHash, [sid], type_desc, isApplied)
	SELECT *
	FROM OPENQUERY([WHSQLWR1], '
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
	
	-- openquery is used so that loginproperty function runs on the remote server, otherwise we get back null
	-- find all logins who are part of server role
	INSERT INTO login_roles(serverRole, memberName, [sid])
	SELECT *
	FROM OPENQUERY([WHSQLWR1], 'exec [MASTER].[DBO].[SP_HELPSRVROLEMEMBER]')	

	--mark the system and local IDs as already having been created so we don't try to process them
	Update logins set isApplied = 1 where loginName like '#%' or loginName like 'NT Service%' or loginName like 'WHSQLWR1%'
	Update login_roles set isApplied = 1 where memberName like '#%' or memberName like 'NT Service%' or memberName like 'WHSQLWR1%'


	--debug
	--select * from logins where isApplied = 0


	--start looping through logins from primary
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
				then 'CREATE LOGIN [' + @loginName + '] WITH PASSWORD = ' + 
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


		-- if the account does exist but password is different, then we need to drop/create; can't alter as hashed isn't supported
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

						SET @sql = 'CREATE LOGIN ' + @loginName + ' WITH PASSWORD = ' + CONVERT(nvarchar(512), 							COALESCE(@password, 'NULL')) + ' HASHED, SID = ' + CONVERT(nvarchar(512), 							COALESCE(@sidplain, 'NULL')) + ', CHECK_POLICY = OFF' 
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

	--see what local roles are defined
	CREATE TABLE #SRV_Roles 
	 (
	  SERVERROLE VARCHAR(100),
	  MEMBERNAME VARCHAR(100),
	  MEMBERSID VARBINARY (85)
	 )


	/*GET SERVER ROLES INTO TEMPORARY TABLE*/
	SET @CMD = '[MASTER].[DBO].[SP_HELPSRVROLEMEMBER]'
	INSERT INTO #SRV_Roles EXEC (@CMD)

	--if the roles defined on primary are different from this server, we need to add those logins to those roles
	--we  need to exclude local accounts
	if exists(select serverRole, memberName from login_roles  where memberName not like  'WHSQLWR1%' except
		select serverrole, membername from #SRV_Roles )
		BEGIN
			--debug
			select serverRole, memberName from login_roles  where memberName not like  'WHSQLWR1%' except select serverrole, membername from #SRV_Roles
	
			DECLARE SERVER_ROLES CURSOR FOR
			Select serverRole ,
			memberName
			FROM login_roles
			where memberName not like  'WHSQLWR1%' except select serverrole, membername from #SRV_Roles

			OPEN SERVER_ROLES 
			FETCH NEXT FROM SERVER_ROLES into @SERVERROLE,@MEMBERNAME

			WHILE (@@fetch_status =0)
			BEGIN
				Set @CMD = ''
				Select @CMD = @CMD + 'EXEC MASTER.DBO.sp_addsrvrolemember @loginame = ' + char(39) + @MEMBERNAME + char(39) + ', @rolename = ' + char(39) + @SERVERROLE + char(39) --+ char(10) + 'GO' + char(10)
				--from ##SRV_Roles --where MemberName = @DatabaseUserName
				Print '--Login:' + @MEMBERNAME 
				Print @CMD
				exec(@CMD)
				FETCH NEXT FROM SERVER_ROLES into @SERVERROLE,@MEMBERNAME
			END

			CLOSE SERVER_ROLES 
			DEALLOCATE SERVER_ROLES 
	
		END
END


GO

 Drop table #SRV_Roles

