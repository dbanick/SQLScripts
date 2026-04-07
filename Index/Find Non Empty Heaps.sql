
SELECT db_name() as DB, SCH.name + '.' + TBL.name AS TableName, idx.type_desc,
i.rowcnt as RowCnt
FROM sys.tables AS TBL 
     INNER JOIN sys.schemas AS SCH 
         ON TBL.schema_id = SCH.schema_id 
     INNER JOIN sys.indexes AS IDX 
         ON TBL.object_id = IDX.object_id 
            AND IDX.type = 0 -- = Heap 
     INNER JOIN sysindexes as i
		ON TBL.object_id = i.id
WHERE i.indid = 0
	AND i.rowcnt > 0      
ORDER BY RowCnt desc, TableName




/* 
--for all databases
create table #rdxNonEmptyHeaps (db varchar(200), tableName varchar(500), rowCnt int)

INSERT INTO #rdxNonEmptyHeaps
exec sp_msforeachdb
'
use ?
SELECT ''?'' as DB, SCH.name + ''.'' + TBL.name AS TableName, 
i.rowcnt as RowCnt
FROM sys.tables AS TBL 
     INNER JOIN sys.schemas AS SCH 
         ON TBL.schema_id = SCH.schema_id 
     INNER JOIN sys.indexes AS IDX 
         ON TBL.object_id = IDX.object_id 
            AND IDX.type = 0 -- = Heap 
     INNER JOIN sysindexes as i
		ON TBL.object_id = i.id  
			AND i.rowcnt > 0      
ORDER BY RowCnt desc, TableName
'

select distinct db, tableName, rowCnt from #rdxNonEmptyHeaps order by 1,2
go
drop table #rdxNonEmptyHeaps

*/