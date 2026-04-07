select name, database_name, type, backup_start_date, backup_finish_date from msdb.dbo.backupset
where database_name = 'STS_APP' --replace with database name
and backup_start_date > '2016-02-06' --replace with correct start date
order by backup_start_date desc
go