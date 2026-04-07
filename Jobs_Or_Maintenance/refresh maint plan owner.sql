select @@servername
use msdb
select name, SUSER_SNAME(ownersid)
from sysssispackages where SUSER_SNAME(ownersid) != 'sa'



UPDATE [msdb].[dbo].[sysssispackages]
SET [ownersid] = 0x01 --sa user
WHERE [name] = 'MaintenancePlan' 