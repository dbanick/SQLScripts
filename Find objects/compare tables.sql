create table #temprdx (TableName varchar(255),
INFOGEN_ColumnName varchar(255),
POSDB_ColumnName varchar(255),
INFOGEN_is_nullable bit,
POSDB_is_nullable bit,
INFOGEN_Datatype varchar(100),
POSDB_Datatype varchar(100),
INFOGEN_is_identity bit,
POSDB_is_identity bit)

insert into #temprdx
exec sp_MSforeachtable '
select ''?'' [TableName], 
INFOGEN.name as INFOGEN_ColumnName, 
POSDB.name as POSDB_ColumnName, 
INFOGEN.is_nullable as INFOGEN_is_nullable, 
POSDB.is_nullable as POSDB_is_nullable, 
INFOGEN.system_type_name as INFOGEN_Datatype, 
POSDB.system_type_name as POSDB_Datatype, 
INFOGEN.is_identity_column as INFOGEN_is_identity, 
POSDB.is_identity_column as POSDB_is_identity  
FROM sys.dm_exec_describe_first_result_set (N''SELECT * FROM ?'', NULL, 0) INFOGEN
FULL OUTER JOIN  sys.dm_exec_describe_first_result_set (N''SELECT * FROM posdb01v.ig_log.?'', NULL, 0) POSDB 
ON INFOGEN.name = POSDB.name 
'

select * from #temprdx

drop table #temprdx