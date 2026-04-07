DECLARE @finishdate datetime
DECLARE @deletedate datetime
SET @finishdate = (SELECT 
   msdb.dbo.backupset.backup_finish_date
--rtrim(reverse(substring(reverse(msdb.dbo.backupmediafamily.physical_device_name),0,patindex('%\%',reverse(msdb.dbo.backupmediafamily.physical_device_name)))))
--   msdb.dbo.backupmediafamily.physical_device_name  
 FROM   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  backupset.database_name = 'goSection8' --uncomment front of line and change name in quotes to specify specific db
and rtrim(reverse(substring(reverse(msdb.dbo.backupmediafamily.physical_device_name),0,patindex('%\%',reverse(msdb.dbo.backupmediafamily.physical_device_name))))) in (
		select rtrim(reverse(substring(reverse(last_restored_file),0,patindex('%\%',reverse(last_restored_file))))) 
		from [90839-12\SQLDB].msdb.dbo.log_shipping_secondary_databases
		where secondary_Database = 'gosection8'))

SET @deletedate = dateadd(hour, -4, @finishdate)

select @deletedate
--EXECUTE master.dbo.xp_delete_file 0,N'\\90839-12\D$\SQL\Backup\SQLDB\GoSection8',N'trn',@finishdate,1
