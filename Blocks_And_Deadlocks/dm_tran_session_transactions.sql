--dm_tran_session_transactions joined with sp_who2

use tempdb
--SP_WHO2
create table #spWho
(
	SPID int,
	Status varchar(100),
	[Login] varchar(100),
	HostName varchar(100),
	BlkBy varchar(100),
	DBName varchar(100),
	Command varchar(100),
	CPUTIME varchar(100),
	DISKIO varchar(100),
	LASTBATCH varchar(100),
	PROGRAMNAME varchar(100),
	SPID1 varchar(100),
	REQUESTID varchar(100)	
)

insert into #spWho 
exec('sp_who2')

--Transaction DMV
create table #trans 
(
"session_id" int,
"database_name" varchar (100),
"transaction_state" varchar (100),
"read_write_start_time" varchar (100),
"database_transaction_log_record_count" int,
"database_transaction_log_bytes_used" int
)

insert into #trans
SELECT  
st.session_id ,
        DB_NAME(dt.database_id) AS database_name ,
        CASE WHEN dt.database_transaction_begin_time IS NULL THEN 'read-only'
             ELSE 'read-write'
        END AS transaction_state ,
        dt.database_transaction_begin_time AS read_write_start_time ,
        dt.database_transaction_log_record_count ,
        dt.database_transaction_log_bytes_used
       
FROM    sys.dm_tran_session_transactions AS st
        INNER JOIN sys.dm_tran_database_transactions AS dt
            ON st.transaction_id = dt.transaction_id



--select from Joined tables
select
t."session_id" as "SPID",
s.BlkBy,
t."database_name",
t."transaction_state",
t."read_write_start_time",
s.LASTBATCH,
t."database_transaction_log_record_count" as "Log Record Count",
t."database_transaction_log_bytes_used",
s.[Login],
s.DISKIO

from #trans as t
Inner join #spWho as s
on s.SPID = t.session_id

--search for particular SPID
--where SPID = '59'


ORDER BY t.session_id ,
       t.database_name
       
       

  
  
  --cleanup
  drop table #trans
  drop table #spWho
