/* ********************************************************************                            
**              CHANGE HISTORY                            
***********************************************************************                            
**   Date:       Author:       Descriptiion:      
**   ----------  -----------   --------------      
**   11-07-2011 Srinivas Sankasani      INTIAL Migration of Logins/Server Roles from 2005/2008 to 2005/2008
**   __________  ____________  ________________________________________                            
** *******************************************************************/ 
--
--###############################[SQL Login]############################
USE master
SET NOCOUNT ON
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
 CREATE PROCEDURE sp_help_revlogin @login_name sysname = NULL,
                @include_db   BIT  = 0,
                @include_role BIT  = 0 AS
 
 DECLARE @xstatus INT
 --DECLARE  @binpwd VARBINARY(256)
 --DECLARE  @dfltdb VARCHAR(256)
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
 DECLARE @DatabaseUserName sysname
 DECLARE @cmd varchar(max)
 DECLARE @SERVERROLE VARCHAR(100)
 DECLARE @MEMBERNAME VARCHAR(100)  
 DECLARE @defaultdb sysname
 
 CREATE TABLE ##SRV_Roles 
 (
  SERVERROLE VARCHAR(100),
  MEMBERNAME VARCHAR(100),
  MEMBERSID VARBINARY (85)
 )
 
IF (@login_name IS NULL)
   DECLARE login_curs CURSOR STATIC FOR
 
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
    
    
     IF @include_db = 1
    BEGIN
      PRINT ''
      
      PRINT ''
      
      PRINT ''
      
      PRINT '/***** SET DEFAULT DATABASES *****/'
      
    FETCH FIRST FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
           
      WHILE @@FETCH_STATUS = 0
        BEGIN
          PRINT ''
          
          SET @tmpstr = '-- Login: ' + @name
          
          PRINT @tmpstr
          SET @tmpstr = 'ALTER LOGIN [' + @name + '] WITH DEFAULT_DATABASE=[' + @defaultdb + ']'
          --SET @tmpstr = 'ALTER LOGIN [' + @name + '] WITH DEFAULT_DATABASE=[' + @dfltdb + ']'
          
          PRINT @tmpstr
          
         FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
        END
    END
    
  IF @include_role = 1
    BEGIN
      PRINT ''
      
      PRINT ''
      
      PRINT ''
      
     PRINT '/***** SET SERVER ROLES *****/'
     Print '--BEGIN ************************************'


 /*GET SERVER ROLES INTO TEMPORARY TABLE*/
 SET @CMD = '[MASTER].[DBO].[SP_HELPSRVROLEMEMBER]'
 INSERT INTO ##SRV_Roles EXEC (@CMD)

 DECLARE SERVER_ROLES CURSOR FOR
   Select SERVERROLE ,
     MEMBERNAME
   FROM ##SRV_Roles

 OPEN SERVER_ROLES 
 FETCH NEXT FROM SERVER_ROLES into @SERVERROLE,@MEMBERNAME

 WHILE (@@fetch_status =0)
  BEGIN
   Set @CMD = ''
   Select @CMD = @CMD + 'EXEC MASTER.DBO.sp_addsrvrolemember @loginame = ' + char(39) + @MEMBERNAME + char(39) + ', @rolename = ' + char(39) + @SERVERROLE + char(39) + char(10) + 'GO' + char(10)
   --from ##SRV_Roles --where MemberName = @DatabaseUserName
   Print '--Login:' + @MEMBERNAME 
   Print @CMD
  FETCH NEXT FROM SERVER_ROLES into @SERVERROLE,@MEMBERNAME
 END

 CLOSE SERVER_ROLES 
 DEALLOCATE SERVER_ROLES 
 
 Drop table ##SRV_Roles


     
END
 
 CLOSE login_curs
 DEALLOCATE login_curs
 RETURN 0
 GO
 exec sp_help_revlogin @login_name=NULL, @include_db=1, @include_role=1
 GO