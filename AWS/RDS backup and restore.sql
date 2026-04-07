exec msdb.dbo.rds_backup_database 
  @source_db_name='Taxwtk_prod_v43', 
  @s3_arn_to_backup_to='arn:aws:s3:::dbe-entsvcs-prod-rds-bucket/Taxwtk_prod_v43_full_20241203.bak', 
  @overwrite_S3_backup_file=1,
  @type = 'Full',
  @number_of_files = 1


exec msdb.dbo.rds_restore_database 
  @restore_db_name='Taxwtk_prod_v43mn', 
  @s3_arn_to_restore_from='arn:aws:s3:::dbe-entsvcs-prod-rds-bucket/Taxwtk_prod_v43_full_20241203.bak'