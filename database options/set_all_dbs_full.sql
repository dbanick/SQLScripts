--this will set all user databases to FULL recovery model

DECLARE @SQL VARCHAR(1000)  
DECLARE @DB sysname  

DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR  
   SELECT [name]  
   FROM master..sysdatabases 
   WHERE [name] NOT IN ('tempdb', 'master', 'msdb') 
   and CAST(DATABASEPROPERTYEX(name, 'Recovery')as varchar(15)) = 'SIMPLE'
   ORDER BY [name] 

OPEN curDB  
FETCH NEXT FROM curDB INTO @DB  
WHILE @@FETCH_STATUS = 0  
   BEGIN  
       SELECT @SQL = 'USE [master]' + CHAR(13) + 'ALTER DATABASE [' + @DB +'] SET RECOVERY FULL' + CHAR(13)  
       --EXEC(@SQL)
	   select(@SQL)
       FETCH NEXT FROM curDB INTO @DB  
   END  
    
CLOSE curDB  
DEALLOCATE curDB