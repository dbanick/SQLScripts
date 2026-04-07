SET NOCOUNT OFF  
DECLARE @strSQL NVARCHAR(400) --variable for dynamic SQL statement - variable size can change depending on the length of database names 
DECLARE @strDatabasename NVARCHAR(250) --variable for database name 
DECLARE MyCursor CURSOR FOR --used for cursor allocation  
   SELECT name FROM master.sys.databases a 
   INNER JOIN master.sys.database_mirroring b 
   ON a.database_id=b.database_id 
   WHERE NOT b.mirroring_guid IS NULL -- only mirrored databases
OPEN MyCursor  
FETCH Next FROM MyCursor INTO @strDatabasename  
WHILE @@Fetch_Status = 0  
BEGIN  
   ---Run the ALTER DATABASE
   SET @strSQL = 'ALTER DATABASE [' + @strDatabaseName + '] SET PARTNER SUSPEND'  
   --EXEC sp_executesql @strSQL  
   print @strSQL
   PRINT 'Pausing ' + @strDatabaseName  
   PRINT '========================================'     
FETCH Next FROM MyCursor INTO @strDatabasename  
END   
CLOSE MyCursor  
DEALLOCATE MyCursor  






SET NOCOUNT OFF  
DECLARE @strSQL NVARCHAR(400) --variable for dynamic SQL statement - variable size can change depending on the length of database names 
DECLARE @strDatabasename NVARCHAR(250) --variable for database name 
DECLARE MyCursor CURSOR FOR --used for cursor allocation  
   SELECT name FROM master.sys.databases a 
   INNER JOIN master.sys.database_mirroring b 
   ON a.database_id=b.database_id 
   WHERE NOT b.mirroring_guid IS NULL -- only mirrored databases
OPEN MyCursor  
FETCH Next FROM MyCursor INTO @strDatabasename  
WHILE @@Fetch_Status = 0  
BEGIN  
   ---Run the ALTER DATABASE
   SET @strSQL = 'ALTER DATABASE [' + @strDatabaseName + '] SET PARTNER RESUME'  
   --EXEC sp_executesql @strSQL  
   print @strSQL
   PRINT 'Resuming ' + @strDatabaseName  
   PRINT '========================================'     
FETCH Next FROM MyCursor INTO @strDatabasename  
END   
CLOSE MyCursor  
DEALLOCATE MyCursor  






