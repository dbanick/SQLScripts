USE tempdb
SELECT SUM (version_store_reserved_page_count) AS Version_Store_Reserved,
SUM (user_object_reserved_page_count) AS User_Object_Reserverd,
SUM (internal_object_reserved_page_count) AS Internal_Object_Reserved,
SUM (mixed_extent_page_count) AS Mixed_Extent
FROM sys.dm_db_file_space_usage


SELECT
  DB_NAME(database_id) as 'DatabaseName',
  reserved_page_count,
  reserved_space_kb /1024 as [reserved mb]
FROM sys.dm_tran_version_store_space_usage
order by reserved_space_kb desc


SELECT session_id, elapsed_time_seconds
FROM sys.dm_tran_active_snapshot_database_transactions