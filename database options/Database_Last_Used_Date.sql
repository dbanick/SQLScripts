--this script will attempt to show when a database was last used; this is based on read/write activity since the cache was flushed

select 
stat.database_id as database_id
,db.name as database_name
,max(stat.last_user_scan) as last_user_scan
from  sys.dm_db_index_usage_stats as stat
join sys.databases as db
on db.database_id = stat.database_id
group by stat.database_id,db.name
order by db.name asc

SELECT DB_NAME(database_id), LastRead = MAX(CASE
WHEN last_user_seek > last_user_scan AND last_user_seek > last_user_lookup
THEN last_user_seek
WHEN last_user_scan > last_user_seek AND last_user_scan > last_user_lookup
THEN last_user_scan
ELSE last_user_lookup
END
), LastWrite = MAX(last_user_update) FROM
(
SELECT
database_id,
last_user_seek = COALESCE(last_user_seek, '19000101'),
last_user_scan = COALESCE(last_user_scan, '19000101'),
last_user_lookup = COALESCE(last_user_lookup, '19000101'),
last_user_update = COALESCE(last_user_update, '19000101')
FROM sys.dm_db_index_usage_stats
) x
GROUP BY DB_NAME(database_id)
ORDER BY 1;

