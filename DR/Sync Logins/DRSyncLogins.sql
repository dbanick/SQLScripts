--:setvar PRIMARY "SQLRTBAPVS\SQLRTBAP"

SET NOCOUNT ON

USE [master]
GO

CREATE TABLE #logins
(
	loginId int IDENTITY(1, 1) NOT NULL,
	loginName nvarchar(128) NOT NULL,
	passwordHash varbinary(256) NULL,
	[sid] varbinary(85) NOT NULL,
	type_desc varchar(100)
)

-- openquery is used so that loginproperty function runs on the remote server, otherwise we get back null
INSERT INTO #logins(loginName, passwordHash, [sid], type_desc)
SELECT *
FROM OPENQUERY([$(PRIMARY)], '
SELECT
	[name]
	,CONVERT(varbinary(256), LOGINPROPERTY(name, ''PasswordHash''))
	,[sid]
	,type_desc
FROM
	master.sys.server_principals
where
	name NOT IN (''sa'', ''guest'')
and
	[name] not like ''sa%''
ORDER BY name')

--select * from #logins

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

SELECT
	@loginId = 1
	,@count = COUNT(*)
FROM #logins

WHILE @loginId <= @count
BEGIN
	SELECT
		@loginName = loginName
		,@passwordHashNew = passwordHash
		,@sid = [sid]
		,@type_desc = type_desc
	FROM
		#logins
	WHERE
		loginId = @loginId

	-- if the account doesn't exist, then we need to create it
	IF NOT EXISTS (SELECT * FROM master.sys.server_principals WHERE name = @loginName)
	BEGIN
		EXEC master.dbo.sp_hexadecimal @passwordHashNew, @password OUTPUT
		EXEC master.dbo.sp_hexadecimal @sid, @sidplain OUTPUT

		SET @sql = 	case
						when @type_desc = 'SQL_LOGIN' then 'CREATE LOGIN ' + @loginName + ' WITH PASSWORD = ' + CONVERT(nvarchar(512), COALESCE(@password, 'NULL')) + ' HASHED, SID = ' + CONVERT(nvarchar(512), COALESCE(@sidplain, 'NULL')) + ', CHECK_POLICY = OFF' 
						when @type_desc IN ( 'WINDOWS_GROUP', 'WINDOWS_LOGIN' ) then 'CREATE LOGIN [' +  @loginName + '] FROM WINDOWS WITH DEFAULT_DATABASE=[master]'
						else 'print ''This is not a SQL or Windows user, skipping'''
					end
		PRINT @sql
		EXEC (@sql)

		PRINT 'login created'
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

			SET @sql = 'CREATE LOGIN ' + @loginName + ' WITH PASSWORD = ' + CONVERT(nvarchar(512), COALESCE(@password, 'NULL')) + ' HASHED, SID = ' + CONVERT(nvarchar(512), COALESCE(@sidplain, 'NULL')) + ', CHECK_POLICY = OFF' 
			EXEC (@sql)

			PRINT 'login "altered"'
		END
		else
		begin
			PRINT 'login "' + @loginName + '" exists with proper password'
		end
	END

	SET @loginId = @loginId + 1
END

DROP TABLE #logins
