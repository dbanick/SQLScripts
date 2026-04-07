--manually restore one log backup, then update data in these two tables

begin tran
update [msdb].[dbo].[log_shipping_secondary_databases]
set last_restored_date = '2016-12-29 13:32:12.527',
last_restored_file = '\\iadsql33\logshipping2\absHire_Historical\absHire_Historical_20161229165920.trn'
where secondary_database = 'absHire_Historical'
commit

update [msdb].[dbo].[log_shipping_monitor_secondary]
set
last_restored_file = '\\iadsql33\logshipping2\absHire_Historical\absHire_Historical_20161229165920.trn'
where secondary_database = 'absHire_Historical' 

--get last_restored_date from this

select top 10 * from msdb.dbo.restorehistory
order by restore_date desc