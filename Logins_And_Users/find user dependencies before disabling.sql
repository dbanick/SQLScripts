SELECT @@servername as server, 'job' as type, s.name ,
  SUSER_SNAME(s.owner_sid) AS owner
FROM msdb..sysjobs s

UNION ALL
select @@servername as server, 'database' as type, name, SUSER_SNAME(owner_sid) as owner from sys.databases


sp_msforeachdb '
use [?]
select @@servername as server, ''[?]'' as db, name, SUSER_SNAME(sid) as username from sys.database_principals 
where SUSER_SNAME(sid) in (''CRANE\ssafick'', ''CRANE\skpartridge'', ''CRANE\tbalsamo'') '



use SSRSSchedule 
select * from sys.schemas
select * from sys.objects where schema_id not in (1,4)