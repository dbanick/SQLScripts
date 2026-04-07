use msdb
select top 100 
r.destination_database_name
,r.restore_history_id	
,r.restore_date	
, b.backup_finish_date
,case when r.restore_type = 'D' then 'Restore from Full Backup' 
	when  r.restore_type = 'I' then 'Restore from Diff Backup'
	when  r.restore_type = 'L' then 'Restore from Log Backup'
	end as 'Restore Type'
,case when r.replace = 0 then 'no' else 'yes' end as 'Replace Option'
,case when r.recovery = 0 then 'no' else 'yes' end as 'Recovery Option'
, b.database_backup_lsn
, b.first_lsn, b.last_lsn
, b.differential_base_lsn
from restorehistory r
join backupset b on b.backup_set_id = r.backup_set_id
--where 
--destination_database_name = 'Database Name' and  -- *for a specific database*
--b.backup_finish_date > getdate()-3 -- *in the past 3 days*
order by r.restore_date desc


use msdb
select top 100 r.restore_date, r.destination_database_name, 
r.user_name, r.restore_type, r.replace, r.recovery
from dbo.restorehistory r 
order by 1 desc

use msdb
select top 100 r.restore_date, r.destination_database_name, 
r.user_name, f.physical_device_name as 'backup_location', r.restore_type, r.replace, r.recovery
from dbo.restorehistory r 
join backupmediafamily f on r.backup_set_id = f.media_set_id
order by 1 desc
