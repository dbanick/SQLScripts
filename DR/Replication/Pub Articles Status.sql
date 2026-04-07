select 
s.srvname as ServerName,
s.dest_db as 'Dest DB',
object_name(objid) as TableName,
s.[status],
s.queued_reinit
from syssubscriptions s
inner join sysarticles a on a.artid=s.artid
inner join syspublications p on a.pubid=p.pubid
where s.srvid = 4 and p.name ='AHT1' and s.status =1
order by 1,2,3
go

Select 
object_name(a.objid) as TableName

from syspublications p
inner join sysarticles a on a.pubid=p.pubid
where p.name ='AHT1'
order by 1

--select * from syspublications
--select * from sysarticles
--artid, name

