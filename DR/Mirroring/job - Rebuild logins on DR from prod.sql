-- do a find and replace on bhpsqlappswv02 and replace with the prod server name

USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO
 
IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin
GO
CREATE PROCEDURE sp_help_revlogin @login_name sysname = NULL AS
DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 
IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR


      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO


/****** Object:  LinkedServer [BHPSQLAPPSWV02]    Script Date: 08/20/2014 12:24:19 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'BHPSQLAPPSWV02', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'BHPSQLAPPSWV02',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL

GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'rpc', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'rpc out', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'use remote collation', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'BHPSQLAPPSWV02', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Patti
-- Create date: 08/20/14
-- Description:	Scripts out login, password, and SID for SQL and Windows logins on production, and recreates on DR
-- Replace '[BHPSQLAPPSWV02]' with the desired production instance
-- =============================================
CREATE PROCEDURE SyncLoginsToDR 
	-- Add the parameters for the stored procedure here
AS
BEGIN

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
	FROM OPENQUERY([BHPSQLAPPSWV02], '
		SELECT [name]
		,CONVERT(varbinary(256), LOGINPROPERTY(name, ''PasswordHash''))
		,[sid]
		,type_desc
		FROM
		master.sys.server_principals
		where
		name NOT IN (''sa'', ''guest'') and
		[name] not like ''sa%''
		ORDER BY name
		')

	-- select * from #logins
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

					SET @sql = 'CREATE LOGIN ' + @loginName + ' WITH PASSWORD = ' + CONVERT(nvarchar(512), 						COALESCE(@password, 'NULL')) + ' HASHED, SID = ' + CONVERT(nvarchar(512), 						COALESCE(@sidplain, 'NULL')) + ', CHECK_POLICY = OFF' 
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
END
GO



USE [msdb]
GO

/****** Object:  Job [Grab Logins from production]    Script Date: 08/20/2014 13:01:18 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/20/2014 13:01:18 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Grab Logins from production', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Runs a variation of sp_helprevlogin against production via a linked server, and recreates the logins with the correct password and sid on DR side.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'BIG\BankersDBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SyncLoginsToDR]    Script Date: 08/20/2014 13:01:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SyncLoginsToDR', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec SyncLoginsToDR', 
		@database_name=N'master', 
		@output_file_name=N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\SyncLoginsToDR.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SyncLoginsToDR', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140820, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'0b2a1baa-ca6b-4ec5-b487-5df94900fcbd'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


