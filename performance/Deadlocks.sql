set nocount on

--BEGIN GATHER ALL DEADLOCK-RELATED RECORDS IN SQL SERVER ERROR LOG
create table #RawLogs  (id int IDENTITY (1, 1), logdate datetime, processinfo nvarchar(50), logtext nvarchar(max))

insert into #RawLogs
exec sp_readerrorlog

declare @results table (id int IDENTITY (1,1),deadlockcount int, logdate datetime, processinfo nvarchar(50), logtext nvarchar(max), oldid int)
declare @dids table (id int, processinfo nvarchar(50), logdate datetime)
declare @rids table (id int, processinfo nvarchar(50), logdate datetime)
declare @wids table (id int, processinfo nvarchar(50), logdate datetime)

insert into @dids
select id, processinfo, logdate
from #RawLogs
where 
logteXt = 'deadlock-list'
order by id

insert into @rids
select id, processinfo, logdate
from #RawLogs
where logteXt = '  resource-list'
order by id

insert into @wids
select max(id) as id, processinfo, logdate
from #RawLogs
where logteXt like '     waiter id=%'
group by processinfo, logdate
order by id

declare @Startid int, @endid int, @processinfo nvarchar(50), @ddate datetime, @did int, @rdate datetime, @rid int, @deadlockcount int
set @deadlockcount = 0
select top 1 @Startid = id from @dids order by id asc

while((select count(id) from @dids) >0)
begin

	set @deadlockcount = @deadlockcount+1

	select @processinfo = processinfo from @dids where id = @Startid order by id asc

	select @ddate = logdate, @did = id from @dids where id = @Startid order by id asc
	select @rdate = logdate, @rid = id from @rids where id > @Startid and processinfo = @processinfo order by id asc

	select top 1 @endid = id from @wids where id > @Startid and processinfo = @processinfo order by id asc

	insert into @results (deadlockcount, logdate, processinfo, logtext, oldid)
	select @deadlockcount, logdate, processinfo, logtext, id
	from #RawLogs
	where
	   id >=@Startid and
	   processinfo = @processinfo and
	   id <= @endid
	order by id asc

	delete @dids where id = @did
	delete @rids where id = @rid
	delete @wids where id = @endid

	select top 1 @Startid = id from @dids order by id asc
end
-- END GATHER ALL DEADLOCK-RELATED RECORDS IN SQL SERVER ERROR LOG

-- BEGIN GATHER EXECUTIONSTACK DETAILS
declare @executionstack table (id int, deadlockcount int, executioncount int, logdate datetime, processinfo nvarchar(50), logtext nvarchar(max))
declare @eids table (id int, deadlockcount int, processinfo nvarchar(50), logdate datetime)
declare @iids table (id int, deadlockcount int, processinfo nvarchar(50), logdate datetime)

declare @deadlockid int, @eid int, @iid int, @executioncount int
set @executioncount = 0
set @deadlockid = 1

insert into @eids
select id, deadlockcount, processinfo, logdate
from @results
where logtext = '    executionStack'

insert into @iids
select id, deadlockcount, processinfo, logdate
from @results
where logtext = '    inputbuf'

while(@deadlockid < (select max(deadlockcount)+1 from @results))
begin

	set @executioncount = @executioncount+1
	
	select top 1 @eid = id, @deadlockid = deadlockcount from @eids order by id asc
	select top 1 @iid = id from @iids order by id asc

	insert into @executionstack (id, deadlockcount, executioncount, logdate, processinfo, logtext)
	select id, deadlockcount, @executioncount, logdate, processinfo, logtext
	from @results r
	where id > @eid-2 and id < @iid
	order by r.id asc

	delete @eids where id = @eid
	delete @iids where id = @iid

	if not exists (select top 1 id, deadlockcount from @eids order by id asc)
		break
	else
		continue
end
-- END GATHER EXECUTIONSTACK DETAILS

/**/
-- BEGIN RETURN NUMBER OF DEADLOCKS
select
distinct top 1 deadlockcount
from @results
order by deadlockcount desc
-- END RETURN NUMBER OF DEADLOCKS
/**/

/**/
-- BEGIN RETURN ALL DEADLOCK INFORMATION FROM THE SQL SERVER ERROR LOG
select 
deadlockcount, logdate, processinfo, 
logtext
--,rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(logtext,'               ',' '),'       ',' '),'     ',' '),'   	',' '),'    ',' '),'  ',' '),'  ',' '),'	',' '))) as logtext_cleaned
from @results
order by id
-- END RETURN ALL DEADLOCK INFORMATION FROM THE SQL SERVER ERROR LOG
/**/

/**/
-- BEGIN RETURN ALL LOCK OBJECTS
select distinct
logtext
from @results 
where 
logtext like '%associatedobjectid%'
-- END RETURN ALL LOCK OBJECTS
/**/

/**/
-- BEGIN GENERATE ASSOCIATEDOBJECTS QUERY (SEND RESULTS TO TEXT, COPY TO NEW WINDOW AND REMOVE LAST 'union', RUN IN DATABASE) 
select distinct
'SELECT OBJECT_NAME(i.object_id) as objectname, i.name as indexname
      FROM sys.partitions AS p
      INNER JOIN sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id
      WHERE p.partition_id = '+convert(varchar(250),REVERSE(SUBSTRING(REVERSE(logtext),0,CHARINDEX('=', REVERSE(logtext)))))+'
	  union
	  '
from @results 
where logtext like '   keylock hobtid=%'
union
select distinct
'SELECT OBJECT_NAME(i.object_id) as objectname, i.name as indexname
      FROM sys.partitions AS p
      INNER JOIN sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id
      WHERE p.partition_id = '+convert(varchar(250),REVERSE(SUBSTRING(REVERSE(logtext),0,CHARINDEX('=', REVERSE(logtext)))))+'
	  union
	  '
from @results
where logtext like '   pagelock fileid=%'
-- END GENERATE ASSOCIATEDOBJECTS QUERY
/**/

/**/ 
-- BEGIN RETURN DISTINCT QUERIES IN SQL SERVER LOG
select
max(deadlockcount) as deadlockcount, max(id) as id, 
logtext
--rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(logtext,'               ',' '),'       ',' '),'     ',' '),'   	',' '),'    ',' '),'  ',' '),'  ',' '),'	',' '))) as logtext_cleaned
from @results
where logtext not in (
'deadlock-list',
'  process-list',
'    inputbuf',
'    executionStack',
'  resource-list',
'    owner-list',
'    waiter-list'
)
and logtext not like '     owner id=%'
and logtext not like '     waiter id=%'
and logtext not like '   keylock hobtid=%'
and logtext not like '   pagelock fileid%'
and logtext not like ' deadlock victim=%'
and logtext not like '   process id=%'
and logtext not like '     frame procname%'
group by 
logtext
--rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(logtext,'               ',' '),'       ',' '),'     ',' '),'   	',' '),'    ',' '),'  ',' '),'  ',' '),'	',' ')))
order by id asc, deadlockcount asc
-- END RETURN DISTINCT QUERIES IN SQL SERVER LOG
/**/

/**/
-- BEGIN RETURN ALL QUERIES PARTICIPATING IN DEADLOCKS
select 
deadlockcount, logdate, processinfo, logtext
--rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(logtext,'               ',' '),'       ',' '),'     ',' '),'   	',' '),'    ',' '),'  ',' '),'  ',' '),'	',' '))) as logtext_cleaned
from @executionstack 
WHERE logtext not like '%process id=%'
and logtext not like '%executionstack%'
order by id asc
-- END RETURN ALL QUERIES PARTICIPATING IN DEADLOCKS

/**/
-- BEGIN RETURN DISTINCT QUERIES KILLED DUE TO DEADLOCK
select max(d.deadlockcount) as deadlockcount, max(d.executioncount) executioncount, max(d.id) as id, logtext
--rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(d.logtext,'               ',' '),'       ',' '),'     ',' '),'   	',' '),'    ',' '),'  ',' '),'  ',' '),'	',' '))) as logtext_cleaned
from @executionstack d
right join (
	select e.executioncount
	from @results r
	join (
		select deadlockcount, logtext, convert(varchar(250),REVERSE(SUBSTRING(REVERSE(logtext),0,CHARINDEX('=', REVERSE(logtext))))) victim
		from @results
		where logtext like ' deadlock victim=%'
	) v on r.deadlockcount=v.deadlockcount
	left join (
		select id, logtext, substring(logtext, charindex('=', logtext)+1,50) processidstart,
		substring(substring(logtext, charindex('=', logtext)+1,50),0, charindex(' ', substring(logtext, charindex('=', logtext)+1,50))) processid
		from @results
		where logtext like '   process id=%'
	) p on r.id=p.id
	join @executionstack e on r.id=e.id
	where v.victim=p.processid
) q on d.executioncount=q.executioncount
where d.logtext not like '   process id=%'
and d.logtext <> '    executionStack'
and d.logtext not like '     frame%'
group by logtext
--rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(logtext,'               ',' '),'       ',' '),'     ',' '),'   	',' '),'    ',' '),'  ',' '),'  ',' '),'	',' ')))
order by id asc, deadlockcount asc, executioncount asc
-- END RETURN DISTINCT QUERIES KILLED DUE TO DEADLOCK 
/**/

/**/
-- BEGIN RETURN ALL QUERIES KILLED DUE TO DEADLOCK
select d.deadlockcount, d.logdate, d.processinfo, logtext
--rtrim(ltrim(replace(replace(replace(replace(replace(replace(replace(replace(d.logtext,'               ',' '),'       ',' '),'     ',' '),'   	',' '),'    ',' '),'  ',' '),'  ',' '),'	',' '))) as logtext_cleaned
from @executionstack d
right join (
	select e.executioncount
	from @results r
	join (
		select deadlockcount, logtext, convert(varchar(250),REVERSE(SUBSTRING(REVERSE(logtext),0,CHARINDEX('=', REVERSE(logtext))))) victim
		from @results
		where logtext like ' deadlock victim=%'
	) v on r.deadlockcount=v.deadlockcount
	left join (
		select id, logtext, substring(logtext, charindex('=', logtext)+1,50) processidstart,
		substring(substring(logtext, charindex('=', logtext)+1,50),0, charindex(' ', substring(logtext, charindex('=', logtext)+1,50))) processid
		from @results
		where logtext like '   process id=%'
	) p on r.id=p.id
	join @executionstack e on r.id=e.id
	where v.victim=p.processid
	--order by r.id
) q on d.executioncount=q.executioncount
where d.logtext not like '   process id=%'
and d.logtext <> '    executionStack'
order by d.id asc
-- END RETURN ALL QUERIES KILLED DUE TO DEADLOCK
/**/

-- BEGIN CLEANUP
drop table #rawlogs
-- END CLEANUP
set nocount off

