--sql 2005 and newer
--if you have issues, try changing the sp_msforeachdb to sp_MSforeachdb
--all names must be wrapped in single quotes
use msdb
create table #loginSearch(
loginName varchar(200),
databaseName varchar(100)
)
insert into #loginSearch
SELECT name, 'server access' as [databaseName] FROM master.sys.syslogins

where name like 
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' 

SET QUOTED_IDENTIFIER OFF
insert into #loginSearch
exec sp_msforeachdb 
"
use [?];
SELECT name as [User Name], '[?]' as [databaseName] FROM dbo.sysusers
where name like 
/* **** replace dbadirect with the user name **** */
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' 
/* replace lines above */
"

SET QUOTED_IDENTIFIER ON
select * from #loginSearch order by 1
drop table #loginSearch


/*
--sql 2000
use msdb
create table #loginSearch(
loginName varchar(200),
databaseName varchar(100)
)
SELECT name, 'server access' as [databaseName] FROM master.dbo.sysxlogins

where name like 
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%'  

SET QUOTED_IDENTIFIER OFF
insert into #loginSearch
exec sp_msforeachdb 
"
use [?];
SELECT name as [User Name], '[?]' as [databaseName] FROM dbo.sysusers
where name like 

/* **** replace dbadirect with the user name **** */
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' or name like
'%dbadirect%' 
/* replace lines above */
"

SET QUOTED_IDENTIFIER ON

select * from #loginSearch order by 1
drop table #loginSearch
*/