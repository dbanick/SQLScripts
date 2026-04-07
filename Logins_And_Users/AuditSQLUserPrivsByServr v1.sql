/*

List specific permissions on objects

sysprotects table -- 

id			int					id of objects to which permissions apply
uid			smallint			id of user to which permissions apply
action		tinyint				
		Can have one of these permissions: 
			26  = REFERENCES
			178 = CREATE FUNCTION
			193 = SELECT
			195 = INSERT
			196 = DELETE
			197 = UPDATE
			198 = CREATE TABLE
			203 = CREATE DATABASE
			207 = CREATE VIEW
			222 = CREATE PROCEDURE
			224 = EXECUTE
			228 = BACKUP DATABASE
			233 = CREATE DEFAULT
			235 = BACKUP LOG
			236 = CREATE RULE
protecttype			tinyint				
	Can have these values: 
			204 = GRANT_W_GRANT
			205 = GRANT
			206 = REVOKE
*/

set nocount on

--print 'Running for Server $(SQLSRV), database $(DBNM)'

if exists (SELECT 1 FROM tempdb.dbo.sysobjects where name like '#PermissionTypes%')
	drop table #PermissionTypes

create table #PermissionTypes (  PermValue int, Privilege varchar(50) )

insert #PermissionTypes values (26, 'REFERENCES')
insert #PermissionTypes values (178, 'CREATE FUNCTION')
insert #PermissionTypes values (193, 'SELECT')
insert #PermissionTypes values (195, 'INSERT')
insert #PermissionTypes values (196, 'DELETE')
insert #PermissionTypes values (197, 'UPDATE')
insert #PermissionTypes values (198, 'CREATE TABLE')
insert #PermissionTypes values (203, 'CREATE DATABASE')
insert #PermissionTypes values (207, 'CREATE VIEW')
insert #PermissionTypes values (222, 'CREATE PROCEDURE')
insert #PermissionTypes values (224, 'EXECUTE')
insert #PermissionTypes values (228, 'BACKUP DATABASE')
insert #PermissionTypes values (233, 'CREATE DEFAULT')
insert #PermissionTypes values (235, 'BACKUP LOG')
insert #PermissionTypes values (236, 'CREATE RULE')
insert #PermissionTypes values (204, 'GRANT_W_GRANT')
insert #PermissionTypes values (205, 'GRANT')
insert #PermissionTypes values (206, 'REVOKE')



-- 0) Create temporary table #UserPrivs to store all users and privileges

if exists (SELECT 1 FROM tempdb.dbo.sysobjects where name like '#UserPrivs%')
	drop table #UserPrivs

create table #UserPrivs
(
	[Priority] int,
	[Server] sysname,
	[Database] sysname,
	[User/Role] sysname,
	[Type] varchar(20),
	[Privilege] varchar(500)
)



/* 1) List all the server level ADMINS
*/

if exists (SELECT 1 FROM tempdb.dbo.sysobjects where name like '#SrvRoles%')
	drop table #SrvRoles

create table #SrvRoles ( ServerRole sysname, [Description] sysname )

insert #SrvRoles exec sp_helpsrvrole

insert #UserPrivs
select
	1 as [Priority],
	@@servername as [Server],
	'All databases' as [Database], 
	ServerRole as [User],
	'SYS ROLE' as [Type],
	[Description] as Privilege
from #SrvRoles

if exists (SELECT 1 FROM tempdb.dbo.sysobjects where name like '#SrvRoleMembers%')
	drop table #SrvRoleMembers

create table #SrvRoleMembers ( ServerRole sysname, MemberName sysname, MemberSID varchar(200) )

insert #SrvRoleMembers exec sp_helpsrvrolemember

insert #UserPrivs
select
	10 as [Priority],
	@@servername as [Server],
	'All databases' as [Database], 
	MemberName as [User],
	CASE 
		WHEN sl.isntgroup = 1 THEN 'WIN GROUP'
		WHEN sl.isntuser = 1 THEN 'WIN USER'
	else 'SQL USER'
	END AS 'Type',
--	'SYS USER' as [Type],
	'Server Role ' + ServerRole as Privilege
from #SrvRoleMembers sr
join master.dbo.syslogins sl on sr.MemberSID = sl.sid
where MemberName not like '%$%'

/* 2) List all fixed database roles
*/

insert #UserPrivs
select
	30 as [Priority],
	@@servername as [Server],
	'Any database' as [Database], 
	su.name as [User], 
	CASE 
		WHEN su.isntgroup = 1 THEN 'WIN GROUP'
		WHEN su.isntuser = 1 THEN 'WIN USER'
		WHEN su.issqluser = 1 THEN 'SQL USER'
		WHEN su.issqlrole = 1 THEN 'SQL ROLE'
		WHEN su.isapprole = 1 THEN 'APP ROLE'
	END AS 'Type',
	CASE su.name
		WHEN 'public' THEN 'Public'
		WHEN 'db_owner' THEN 'Database owner; complete control of database'
		WHEN 'db_accessadmin' THEN 'Database access administrator'
		WHEN 'db_securityadmin' THEN 'Database security administrators'
		WHEN 'db_ddladmin' THEN 'Database DDL administrators'
		WHEN 'db_backupoperator' THEN 'Database backup operators'
		WHEN 'db_datareader' THEN 'Database data readers; read any data in database'
		WHEN 'db_datawriter' THEN 'Database data writers; write/modify any table'
		WHEN 'db_denydatareader' THEN 'Database deny read to any table'
		WHEN 'db_denydatawriter' THEN 'Database deny write/modify to any table'
	END AS Privilege
from [master].[dbo].[sysusers] su
where 
	su.issqlrole = 1
	and su.name in 
(
'db_owner',
'db_accessadmin',
'db_securityadmin',
'db_ddladmin',
'db_backupoperator',
'db_datareader',
'db_datawriter',
'db_denydatareader',
'db_denydatawriter'
)

-- ***************************************************************************
-- Declare a cursor to loop through all the databases on the server

DECLARE @SQLCommand varchar(2000), @DBName sysname

DECLARE csrDB CURSOR FOR 
    SELECT name
        FROM master.dbo.sysdatabases
        WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb', 'pubs','Northwind')
	and DATABASEPROPERTYEX(name, 'Status') != 'OFFLINE'
        and DATABASEPROPERTYEX(name, 'Status') != 'RESTORING'
-- INSERT DATABASE NAMES HERE -->
--	and name IN 
--(
--'$(DBNM)'
--)

-- ***************************************************************************
-- Open the cursor and get the first database name
OPEN csrDB
FETCH NEXT 
    FROM csrDB
    INTO @DBName

-- ***************************************************************************
-- Loop through the cursor
WHILE @@FETCH_STATUS = 0
BEGIN

print 'Running for DB ' + @DBNAME

-- 3) List roles assigned to users per database

set @SQLCommand = '' 
+ 'select ' 
+ '40 as [Priority], '
+ '''' + @@servername + ''' as [Server], ' 
+ '''' + @Dbname + ''' as [Database],  ' 
+	'isnull(sl.name, u.name + ''(No Login)'') as [User], '
+	'CASE ' 
+ '		WHEN u.isntgroup = 1 THEN ''WIN GROUP''' 
+ '		WHEN u.isntuser = 1 THEN ''WIN USER'''
+ '		WHEN u.issqluser = 1 THEN ''SQL USER'''
+ '		WHEN u.issqlrole = 1 THEN ''SQL ROLE'''
+ '		WHEN u.isapprole = 1 THEN ''APP ROLE'''
+ '	END AS ''Type'','
+ '	''Role '' + su.name as [Privilege] from [' + @DBName + '].[dbo].[sysusers] su '
+ '	JOIN [' + @DBName + '].[dbo].[sysmembers] sm '
+ '		ON su.uid = sm.groupuid '
+ '	JOIN [' + @DBName + '].[dbo].sysusers u '
+ '		ON sm.memberuid = u.uid '
+ '     LEFT JOIN master.dbo.syslogins sl '
+'		on u.sid = sl.sid '
+ ' where u.islogin = 1'

insert #UserPrivs
exec (@SQLCommand)

-- 4) List permissions assigned to users per database

set @SQLCommand = '' 
+ ' select '
+ ' 50 as [Priority], '
+ '''' + @@servername + ''' as [Server], '
+ '''' + @DBName + ''' as [Database], '
+ '	CASE '
+ '		when su.islogin = 1 then isnull(sl.name, su.name COLLATE SQL_Latin1_General_CP1_CI_AS + ''(No Login)'') '
+ '     else   su.name COLLATE SQL_Latin1_General_CP1_CI_AS'
+ '     END as [User],'	
+ '	CASE '
+ '		WHEN su.isntgroup = 1 THEN ''WIN GROUP'' '
+ '		WHEN su.isntuser = 1 THEN ''WIN USER'' '
+ '		WHEN su.issqluser = 1 THEN ''SQL USER'' '
+ '		WHEN su.issqlrole = 1 THEN ''SQL ROLE'' '
+ '		WHEN su.isapprole = 1 THEN ''APP ROLE'' '
+ '	END AS [Type], '
+ '	pt2.Privilege COLLATE SQL_Latin1_General_CP1_CI_AS + '' '' + pt1.Privilege + '' on '' + so.name as [Privilege] '
+ ' from [' + @DBName + '].[dbo].sysprotects sp '
+ '	LEFT JOIN #PermissionTypes pt1 '
+ '		ON sp.action = pt1.PermValue '
+ '	LEFT JOIN #PermissionTypes pt2 '
+ '		ON sp.protecttype = pt2.PermValue '
+ '	JOIN [' + @DBName + '].[dbo].sysusers su '
+ '		ON sp.uid = su.uid '
+ '	JOIN [' + @DBName + '].[dbo].sysobjects so '
+ '		ON sp.id = so.id '
+ '     LEFT JOIN master.dbo.syslogins sl '
+'		on su.sid = sl.sid '
+' where sp.id > 100 and so.name not like ''dt_%'' and so.name not in (''syssegments'',''sysconstraints'')'


insert #UserPrivs
exec(@SQLCommand)

-- ***************************************************************************
-- Get the next database name
        FETCH NEXT 
            FROM csrDB
            INTO @DBName
-- ***************************************************************************

-- ***************************************************************************
-- End of the cursor loop
    END
-- ***************************************************************************

-- ***************************************************************************
-- Close and deallocate the CURSOR
CLOSE csrDB
DEALLOCATE csrDB
-- ***************************************************************************



/*
	4) Get Members of Windows Groups 
*/

if exists (SELECT 1 FROM tempdb.dbo.sysobjects where name like '#GroupMembers%')
	drop table #GroupMembers

create table #GroupMembers
(
	loginname sysname,
	type varchar(20),
	privilege varchar(100),
	mappedloginname sysname,
	permissionpath varchar(500)
)

DECLARE @SQLCommandGroupMembers varchar(2000), @WinGroupName sysname


DECLARE csrWinGroups CURSOR FOR 
        select distinct [User/Role] from #userprivs
        where type = 'WIN GROUP'
        and [User/Role] not like '%(No Login)'
        and [User/Role] not like 'NT SERVICE\%'
        and [User/Role] not in ('Cincinnati\sqladmins','ga\sqladmins','NT AUTHORITY\NETWORK SERVICE','DTNSQL08\WtechHome','GA\CVG.GAIC.Corp.Support')
	



OPEN csrWinGroups
FETCH NEXT 
    FROM csrWinGroups
    INTO @WinGroupName

WHILE @@FETCH_STATUS = 0
BEGIN

	truncate table #GroupMembers

	print 'Looking up Group ' + @WinGroupName

	insert #GroupMembers	
	EXEC master.dbo.xp_logininfo @WinGroupName, 'members'


	insert #UserPrivs
	select 
	  60 as Priority,
	  @@Servername as [Server],
	  '-' as [Database],
	  @WinGroupName as [User/Role],
	  'MEMBER' as [Type],
	  'GROUP MEMBER ' + loginname
	from #GroupMembers
	where loginname not in ('GA\')

        FETCH NEXT 
            FROM csrWinGroups
            INTO @WinGroupName
END

CLOSE csrWinGroups
DEALLOCATE csrWinGroups


select 
	[Server],
	[Database],
	[User/Role],
	[Type],
	[Privilege],
        [Priority]
from #UserPrivs
--where privilege like 'Role%'
--where   [User/Role] like '%No Login%'
order by 
[Priority], [Server], [Database], [Type], [User/Role]
