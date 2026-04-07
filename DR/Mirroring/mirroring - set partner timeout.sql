--This script does a failover of all the databases in a database mirroring session 
--to the Mirror server. 
--NOTE: Run this script in the PRINCIPLE server instance 
SET NOCOUNT OFF 
DECLARE @strSQL NVARCHAR(200) --variable for dynamic SQL statement - variable size should change depending on the 
DECLARE @strDatabasename NVARCHAR(50) --variable for destination directory 
DECLARE MyCursor CURSOR FOR --used for cursor allocation 
SELECT name FROM master.sys.databases a 
INNER JOIN master.sys.database_mirroring b 
ON a.database_id=b.database_id 
--select * from sys.database_mirroring
WHERE NOT mirroring_guid IS NULL 
AND mirroring_role_desc='PRINCIPAL' 
OPEN MyCursor 
FETCH Next FROM MyCursor INTO @strDatabasename 
WHILE @@Fetch_Status = 0 
BEGIN 
---Run the ALTER DATABASE databaseName SET PARTNER TIMEOUT
SET @strSQL = 'ALTER DATABASE ' + @strDatabaseName + ' SET PARTNER TIMEOUT 60' 
EXEC sp_executesql @strSQL 
print @strSQL
FETCH Next FROM MyCursor INTO @strDatabasename 
END 
CLOSE MyCursor 
DEALLOCATE MyCursor 
