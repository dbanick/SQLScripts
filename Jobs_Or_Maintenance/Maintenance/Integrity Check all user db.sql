DECLARE @SQL VARCHAR(1000)  
DECLARE @DB sysname  

DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR  
   SELECT [name]  
   FROM master..sysdatabases 
   WHERE [name] NOT IN ('tempdb', 'master', 'model', 'msdb') 
   and DATABASEPROPERTYEX(name, 'Status') != 'OFFLINE'
   ORDER BY [name] 
     
OPEN curDB  
FETCH NEXT FROM curDB INTO @DB  
WHILE @@FETCH_STATUS = 0  
   BEGIN  
       SELECT @SQL = 'USE [' + @DB +']' + CHAR(13) + 'DBCC CHECKDB WITH NO_INFOMSGS' + CHAR(13)  
       EXEC(@SQL)
       --PRINT @SQL
       FETCH NEXT FROM curDB INTO @DB  
   END  
    
CLOSE curDB  
DEALLOCATE curDB