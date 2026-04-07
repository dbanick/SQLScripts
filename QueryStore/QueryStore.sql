create table #tmp1 (DBName varchar(100),
		desired_state_desc varchar(10),
        actual_state_desc varchar(10),
        readonly_reason int, 
        current_storage_size_mb int , 
        max_storage_size_mb int,
        max_plans_per_query int)

insert into #tmp1
exec sp_msforeachdb 'use [?];
SELECT  db_name(), desired_state_desc ,
        actual_state_desc ,
        readonly_reason, 
        current_storage_size_mb , 
        max_storage_size_mb ,
        max_plans_per_query 
FROM    sys.database_query_store_options'

select @@SERVERNAME, * from #tmp1

drop table #tmp1