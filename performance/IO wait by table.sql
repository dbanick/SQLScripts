SELECT DB_NAME(database_id), OBJECT_NAME(object_id),
 sum(page_io_latch_wait_count) as 'Total page_io_latch_wait_count', sum(page_io_latch_wait_in_ms) as 'Total page_io_latch_wait_in_ms'
 FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL)
 group by DB_NAME(database_id), OBJECT_NAME(object_id)
 order by 3 DESC