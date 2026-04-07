-- Run from Publisher Database  
-- Get information for all databases 
DECLARE @Detail CHAR(1) 
SET @Detail = 'Y' 
CREATE TABLE #tmp_replcationInfo ( 
ServerName VARCHAR(50),
PublisherDB VARCHAR(128),  
PublisherName VARCHAR(128), 
TableName VARCHAR(128), 
SubscriberServerName VARCHAR(128), 
) 
EXEC sp_msforeachdb  
'use ?; 
IF DATABASEPROPERTYEX ( db_name() , ''IsPublished'' ) = 1 
insert into #tmp_replcationInfo 
select 
@@SERVERNAME 
, db_name() PublisherDB 
, sp.name as PublisherName 
, sa.name as TableName 
, UPPER(srv.srvname) as SubscriberServerName 
from dbo.syspublications sp  
join dbo.sysarticles sa on sp.pubid = sa.pubid 
join dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid 
' 
IF @Detail = 'Y' 
   SELECT * FROM #tmp_replcationInfo 
ELSE 
SELECT * 
FROM #tmp_replcationInfo 
--DROP TABLE #tmp_replcationInfo 

create table #tmp_navi (DatabaseName sysname, TableName sysname)
insert into #tmp_navi
exec sp_msforeachdb 'use [?]
select db_name() as DatabaseName, name as TableName from sys.tables'

SELECT *
FROM #tmp_navi t1
WHERE NOT EXISTS (SELECT t2.TableName FROM #tmp_replcationInfo t2 WHERE t1.DatabaseName = t2.PublisherDB AND t1.TableName = t2.TableName)
--and t1.DatabaseName = 'dbname'
order by 1,2

select * from #tmp_replcationInfo
where PublisherDB like '%time%'