DECLARE @sql VARCHAR(500) 
SELECT @sql = 
'use [?] 
select db_name() as database_name
select user_name(uid) as user_name, name, xtype
from [?].dbo.sysobjects
where user_name(uid) = ''GA\lhumbard''
order by user_name, name'

EXEC sp_MSforeachdb @sql 