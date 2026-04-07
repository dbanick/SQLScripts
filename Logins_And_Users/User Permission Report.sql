set nocount on
declare @LoginName varchar(300)
Set @LoginName = 'sbsjung\dbops' -- Enter Login or Windows Group to Report Permissions for

declare @detail bit,@RolePerm bit,@WinGroupMem bit,@WinGroupPerm bit,@LoginType int,@AllDBs bit,@LoginSID varbinary(85),@GroupName varchar(300)

set @AllDBs = 1			-- 1 = All Databases, 0 = Current Database
set @RolePerm = 1		-- Prints Database Role permissions that @LoginName belongs to
set @WinGroupMem = 1	-- Display Windows Groups that the login belongs to if login is not a SQL login
set @WinGroupPerm = 1	-- Prints Windows Group permissions that @LoginName belongs to


Create Table #PermReport ([Instance\Database] varchar(300), [Permission Level] varchar(200), [Permission Path] nvarchar(300), Privilege nvarchar(500))
set @LoginSID = (select SUSER_SID(@LoginName))
create table #t1 (UserName nvarchar(300), UserSid varbinary(85))
Create table #t2 (AccountName nchar(128),type char(8),Privilege char(9),MappedLoginName nchar(128),PermissionPath nchar(128) null)
insert into #t1 select @LoginName, @LoginSID

/****************************************/
/* Determine if Login is a SQL login ID */
/****************************************/
if (select COUNT(*) from master..syslogins where isntname =0 and isntgroup = 0 and name =@LoginName) <> 0
	Begin
		set @WinGroupMem = 0
		set @WinGroupPerm = 0
	End
If @WinGroupPerm = 1
	set @WinGroupMem = 1
/****************************************************/
/* Determine if Login belongs to any Windows Groups */
/****************************************************/
If @WinGroupMem = 1
	Begin
		declare WinGroupCursor CURSOR for select name from master..syslogins where isntgroup = 1
		Open WinGroupCursor

		Fetch next from WinGroupCursor
		into @GroupName

		WHILE @@FETCH_STATUS = 0
			BEGIN 
				insert into #t2 exec master..xp_logininfo @acctname = @GroupName, @option ='members'
			
		
				Fetch next from WinGroupCursor
				into @GroupName
			End
	CLOSE WinGroupCursor
	DEALLOCATE WinGroupCursor
	--select * from #t2	--Debug
	if (select COUNT(*) from #t2 where AccountName = @LoginName) <> 0
		Begin
			insert into #t1 select PermissionPath, SUSER_SID(PermissionPath) from #t2 where AccountName = @LoginName
			Insert into #PermReport select @@SERVERNAME, 'Windows Group', @LoginName, 'Is a member of the Windows Group '+PermissionPath from #t2 where AccountName = @LoginName
			--select * from #t1	--Debug
		End
	End
/*******************************/
/* Get Server Role Information */
/*******************************/
create table #t3 (ServerRole sysname,MamberName sysname,MemberSID varbinary(85))
insert into #t3 exec master..sp_helpsrvrolemember

if (select COUNT(*) from #t3 where MemberSID = @LoginSID) <> 0
	Begin
		Insert into #PermReport Select @@SERVERNAME, 'Server Role', @LoginName, 'Is a member of the server role '+ServerRole from #t3 where MemberSID = @LoginSID
	End
If @WinGroupPerm = 1
	Begin
		Insert into #PermReport Select @@SERVERNAME, 'Server Role', a.UserName, 'Is a member of the server role '+ServerRole from #t3 b, #t1 a where  a.UserSid = b.MemberSID and b.MemberSID <> @LoginSID order by a.UserName
	End
	
	
/********************************************************/
/* Get Database list and check for database permissions */
/********************************************************/

Create table #DBs (name varchar(300))
IF @AllDBs = 1
	Insert into #DBs SELECT name FROM master..sysdatabases where (512 & status) <> 512 and (32 & status) <> 32
  Else
	Insert into #DBs select DB_NAME()

Create table #t4 (DBRole varchar(300), MemberName varchar(300),MemberSid varbinary(85))
Create table #t5 (Owner varchar(300),Object varchar(300),Grantee varchar(300),Grantor varchar(300),ProtectType varchar(20),Action varchar(100),[Column] varchar(100) null)
Create table #t6 (Perm varchar(4000))


If @WinGroupPerm = 0
	Begin
		Truncate table #t1
		insert into #t1 select @LoginName, @LoginSID
	End

declare @dbname varchar(300),@exec varchar(4000)
declare dbcursor CURSOR for SELECT name FROM #Dbs

Open dbcursor

Fetch next from dbcursor
into @dbname

WHILE @@FETCH_STATUS = 0
	BEGIN
		set @exec = ' use ['+@dbname+']
					insert into #t4 exec sp_helprolemember
					insert into #PermReport select '''+@dbname+''', ''Database Role'','''+@LoginName+''', ''Is a member of the database role ''+DBRole from #t4 where MemberSid = SUSER_SID('''+@LoginName+''')
					-- User Permissions
					insert into #t5 exec sp_helprotect
					
					insert into #t6 select 
					rtrim(case when ProtectType = ''Grant_WGO'' then ''Grant'' else ProtectType end)
					+'' ''+
					Action 
					+(case when RTRIM(Owner) <> ''.'' and RTRIM(Object)<> ''.'' then '' on [''+RTRIM(Owner)+''].[''+RTRIM(Object)+'']'' else '''' end)
					+'' ''+RTRIM(case when ProtectType = ''Grant_WGO'' then ''With Grant Option'' else '''' end)
					from #t5 where not [Action] = ''Connect'' and  Grantee = '''+@LoginName+''''
				--select @exec --debug
				Exec(@exec)
			Truncate table #t4
			Truncate Table #t5
			if (select COUNT(*) from #t6) <> 0
				Insert #PermReport Select @dbname, 'Database Permissions', @LoginName, Perm from #t6
			truncate table #t6
			set @exec = ''
			-- WinGroup
			If @WinGroupPerm = 1
				Begin
					set @exec = ' use ['+@dbname+']
					insert into #t4 exec sp_helprolemember
					insert into #PermReport select '''+@dbname+''', ''Database Role'',b.UserName, ''Is a member of the database role ''+a.DBRole from #t4 a,#t1 b where a.MemberSid = b.UserSid and MemberSid <> SUSER_SID('''+@LoginName+''')
					-- Group Permissions
					insert into #t5 exec sp_helprotect
					
					insert into #PermReport select '''+@dbname+''', ''Database Permissions'', a.Grantee,
					rtrim(case when a.ProtectType = ''Grant_WGO'' then ''Grant'' else a.ProtectType end)
					+'' ''+
					a.Action 
					+(case when RTRIM(a.Owner) <> ''.'' and RTRIM(a.Object)<> ''.'' then '' on [''+RTRIM(a.Owner)+''].[''+RTRIM(a.Object)+'']'' else '''' end)
					+'' ''+RTRIM(case when a.ProtectType = ''Grant_WGO'' then ''With Grant Option'' else '''' end)
					from #t5 a,#t1 b where a.Grantee = b.Username and b.usersid <> SUSER_SID('''+@LoginName+''')
					and not a.[Action] = ''Connect'''
				--select @exec --debug
				exec(@exec)
				
				Truncate table #t4
				Truncate Table #t5
				truncate table #t6
				set @exec = ''
				End
			  
			If @RolePerm = 1
				Begin
					set @exec = ' use ['+@dbname+']
					insert into #t4 exec sp_helprolemember
					insert into #t6 select a.DBRole from #t4 a,#t1 b where a.MemberSid = b.UserSid 
					insert into #t5 exec sp_helprotect
					
					insert into #PermReport select '''+@dbname+''', ''Database Role Permissions'', a.Grantee,
					rtrim(case when a.ProtectType = ''Grant_WGO'' then ''Grant'' else a.ProtectType end)
					+'' ''+
					a.Action 
					+(case when RTRIM(a.Owner) <> ''.'' and RTRIM(a.Object)<> ''.'' then '' on [''+RTRIM(a.Owner)+''].[''+RTRIM(a.Object)+'']'' else '''' end)
					+'' ''+RTRIM(case when a.ProtectType = ''Grant_WGO'' then ''With Grant Option'' else '''' end)
					from #t5 a,#t6 b where a.Grantee = b.perm and not a.[Action] = ''Connect'''
					--select @exec --debug
					exec(@exec)
					--select @dbname,* from #t4
					Truncate table #t4
					Truncate Table #t5
					truncate table #t6
					set @exec = ''
				End
		Fetch next from dbcursor
		into @dbname
	End

CLOSE dbcursor
DEALLOCATE dbcursor
-- Report
--select * from #t1
select * from #PermReport

go
drop table #t1
drop table #t2
drop table #t3
drop table #t4
drop table #t5
drop table #t6
drop table #DBs
drop table #PermReport
go