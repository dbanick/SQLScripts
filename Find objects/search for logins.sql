--sql 2005 and newer
use msdb
create table #loginSearch(
loginName varchar(200),
databaseName varchar(100)
)
insert into #loginSearch
SELECT name, 'server access' as [databaseName] FROM master.sys.syslogins

where name like 
'%dbadirect%' or name like
'%VSanders%' or name like
'%ttramsey%' or name like
'%cmermis%' or name like
'%jmontague%' or name like
'%jfaber%' or name like
'%sfuerst%' or name like
'%rnhelms%' or name like
'%lrmalone%' or name like
'%jcolson%' or name like
'%jtate%' or name like
'%SGreenmyer%' or name like
'%jtunison%' or name like
'%spaster%' or name like
'%jfaber%' or name like
'%pfleecs%' or name like
'%gvoges%' 

insert into #loginSearch
exec sp_msforeachdb 
'
use [?];
SELECT name as [User Name], ''[?]'' as [databaseName] FROM dbo.sysusers
where name like 
''%dbadirect%'' or name like
''%VSanders%'' or name like
''%ttramsey%'' or name like
''%cmermis%'' or name like
''%jmontague%'' or name like
''%jfaber%'' or name like
''%sfuerst%'' or name like
''%rnhelms%'' or name like
''%lrmalone%'' or name like
''%jcolson%'' or name like
''%jtate%'' or name like
''%SGreenmyer%'' or name like
''%jtunison%'' or name like
''%spaster%'' or name like
''%jfaber%'' or name like
''%pfleecs%'' or name like
''%gvoges%'' 
'
select * from #loginSearch order by 1
drop table #loginSearch


/*
--sql 2000
use msdb
SELECT name, 'server access' as [databaseName] FROM master.dbo.sysxlogins

where name like 
'%JLBrooks%' or name like
'%VSanders%' or name like
'%ttramsey%' or name like
'%cmermis%' or name like
'%jmontague%' or name like
'%jfaber%' or name like
'%sfuerst%' or name like
'%rnhelms%' or name like
'%lrmalone%' or name like
'%jcolson%' or name like
'%jtate%' or name like
'%SGreenmyer%' or name like
'%jtunison%' or name like
'%spaster%' or name like
'%jfaber%' or name like
'%pfleecs%' or name like
'%gvoges%' 

insert into #loginSearch
exec sp_msforeachdb 
'
use [?];
SELECT name as [User Name], ''[?]'' as [databaseName] FROM dbo.sysusers
where name like 
''%JLBrooks%'' or name like
''%VSanders%'' or name like
''%ttramsey%'' or name like
''%cmermis%'' or name like
''%jmontague%'' or name like
''%jfaber%'' or name like
''%sfuerst%'' or name like
''%rnhelms%'' or name like
''%lrmalone%'' or name like
''%jcolson%'' or name like
''%jtate%'' or name like
''%SGreenmyer%'' or name like
''%jtunison%'' or name like
''%spaster%'' or name like
''%jfaber%'' or name like
''%pfleecs%'' or name like
''%gvoges%'' 
'

select * from #loginSearch order by 1
drop table #loginSearch
*/