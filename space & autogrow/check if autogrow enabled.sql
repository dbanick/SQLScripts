create table #tempAutogrow(
databaseName ntext,
name ntext,
autoGrow varchar(20))

insert into #tempAutogrow
exec
sp_msforeachdb 
'Use [?]; Select ''?'' 
As [Database], 
name As FileName, 
case 
when growth = 0 
Then ''Off'' 
Else ''On'' 
End As AutoGrow 
From sysfiles'

select * from #tempAutogrow
-- where autoGrow = 'Off'
order by autoGrow

drop table #tempAutogrow

