use tempdb

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


SELECT
SUM (user_object_reserved_page_count)*8 as usr_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8 as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage

SELECT R1.session_id, R1.request_id,
R1.request_internal_objects_alloc_page_count, R1.request_internal_objects_dealloc_page_count,
R2.sql_handle, R2.statement_start_offset, R2.statement_end_offset, R2.plan_handle
,R3.text
FROM (SELECT session_id, request_id,
SUM(internal_objects_alloc_page_count) AS request_internal_objects_alloc_page_count,
SUM(internal_objects_dealloc_page_count)AS request_internal_objects_dealloc_page_count
FROM sys.dm_db_task_space_usage
GROUP BY session_id, request_id)
R1
INNER JOIN sys.dm_exec_requests R2 ON R1.session_id = R2.session_id and R1.request_id = R2.request_id
OUTER APPLY sys.dm_exec_sql_text(R2.sql_handle) AS R3
where r3.text is not null
