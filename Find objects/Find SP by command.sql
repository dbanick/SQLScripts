--2005+
SELECT OBJECT_NAME(object_id) 
    FROM sys.sql_modules 
    WHERE Definition LIKE '%SELECT DISTINCT TOP 24%' 
    AND OBJECTPROPERTY(object_id, 'IsProcedure') = 1 



--2005+
select ROUTINE_NAME, ROUTINE_DEFINITION from    
INFORMATION_SCHEMA.ROUTINES where ROUTINE_DEFINITION like '%SELECT%' 


--check all dbs
use msdb
exec sp_msforeachdb
'
use [?]
select ''?'' as [db], ROUTINE_NAME, ROUTINE_DEFINITION from    
INFORMATION_SCHEMA.ROUTINES where ROUTINE_DEFINITION like ''%SELECT TOP%'' 
'