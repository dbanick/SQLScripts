--This will compare index names between 2 databases to identify mis matches

/*
--create tmp table
CREATE TABLE [dbo].[tmp_index_compare](
	[db] [varchar](150) NOT NULL,
	[tableName] [sysname] NOT NULL,
	[indexName] [sysname] NULL
) ON [PRIMARY]
GO

--populate with index info from each db
use [DB-Live_AB_Reporting]
insert into msdb..[tmp_index_compare]
select 'DB-Live_AB_Reporting' as db, object_name (ind.object_id) as tablename, ind.name as indexname  from sys.indexes ind
INNER JOIN
     sys.tables t ON ind.object_id = t.object_id
WHERE
     t.is_ms_shipped = 0

use [DB-Live_SK_Reporting]
insert into msdb..[tmp_index_compare]
select 'DB-Live_SK_Reporting' as db, object_name (ind.object_id) as tablename, ind.name as indexname  from sys.indexes ind
INNER JOIN
     sys.tables t ON ind.object_id = t.object_id
WHERE
     t.is_ms_shipped = 0

*/
--compare data
use msdb;
with U as (

select 'Only in AB' as diff, AB.* from 
(
SELECT  db, tablename, indexname as indexname from tmp_index_compare a where db = 'DB-Live_AB_Reporting'
 and not exists
(SELECT tablename, indexname as indexname from tmp_index_compare b where db = 'DB-Live_SK_Reporting' and a.tablename = b.tableName and a.indexName = b.indexName)

)AB

UNION ALL

select 'Only in SK' as diff, SK.* from 
(SELECT  db, tablename, indexname as indexname from tmp_index_compare a where db = 'DB-Live_SK_Reporting'
and not exists
(SELECT tablename, indexname as indexname from tmp_index_compare b where db = 'DB-Live_AB_Reporting' and a.tablename = b.tableName and a.indexName = b.indexName)
)SK

)

select  @@servername as server, u.db as [database], u.diff as location, u.tablename, u.indexname from U