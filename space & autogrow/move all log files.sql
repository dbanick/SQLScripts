use master
go
select 'alter database [' +db_name(dbid) +'] MODIFY FILE (NAME = '+ name +', FILENAME = ''L:\_SQLLogs\'+rtrim(reverse(substring(reverse(fileName),0,patindex('%\%',reverse(fileName)))))+''')'
from sysaltfiles where dbid> 4 --dbid> 4 means not master, model, msdb, tempdb
and groupid =0 -- groupid 0 = logs
--and filename like 'D:\_SQLData%' -- you can set this to a location if you only want to move logs that live on a certain drive already


select 'alter database [' +db_name(dbid) +'] SET OFFLINE WITH ROLLBACK IMMEDIATE'
from sysaltfiles where dbid> 4 
and fileid =2 
--and filename like 'D:\_SQLData%'

SELECT '********* MOVE THE FILES THEN RUN THE LAST SCRIPT **************'

select 'alter database [' +db_name(dbid) +'] SET ONLINE'
from sysaltfiles where dbid> 4 
and fileid =2 
--and filename like 'D:\_SQLData%'
