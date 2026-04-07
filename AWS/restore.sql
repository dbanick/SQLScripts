USE [msdb]
GO
 
DECLARE	@return_value int
 
EXEC	@return_value = [dbo].[rds_restore_database]
		@restore_db_name = 'TaxDB1',
		--@kms_master_key_arn='arn:aws:s3:us-west-2:704236057354:accesspoint/esb-dev-db',
		@type= 'Full',
		@s3_arn_to_restore_from = N'arn:aws:s3:::rei-db-backup/TaxDB.bak',
		@with_norecovery = 0
 
SELECT	'Return Value' = @return_value
 
GO
 
 
s3://dbe-tf-state-bucket/state/
 
--exec msdb..rds_task_status @task_id= 27