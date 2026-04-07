DECLARE @DBMirroringState VARCHAR(30),@DB_ID INT,@ErrorMessageToSend VARCHAR(100)
DECLARE @MirroredDatabases TABLE (DatabaseID INT, mirroring_state_desc VARCHAR(30))
DECLARE @DBNAME VARCHAR(30)

-- get status for mirrored databases 
INSERT INTO @MirroredDatabases(DatabaseID,mirroring_state_desc)
SELECT database_id, mirroring_state_desc 
FROM    [sys].[database_mirroring]
WHERE  mirroring_role_desc IN ('PRINCIPAL','MIRROR') 
             AND mirroring_state_desc NOT IN ('SYNCHRONIZED','SYNCHRONIZING') 

WHILE EXISTS (SELECT TOP 1 DatabaseID FROM @MirroredDatabases WHERE mirroring_state_desc IS NOT NULL) 
BEGIN
     SELECT TOP 1 
                   @DB_ID = DatabaseID,
                   @DBMirroringState = mirroring_state_desc 
     FROM    @MirroredDatabases 

    SET @ErrorMessageToSend = 'DBMirroring Error on DB:'+@@SERVERNAME+'..'+CAST(DB_NAME(@DB_ID) AS VARCHAR)+
                                           ',DBState=' + @DBMirroringState 

   -- Send Email
   EXEC msdb.dbo.sp_send_dbmail @profile_name='administrator',@recipients='it.database.sqlalerts@basspro.com', 
                                              @body = @ErrorMessageToSend,@subject = @ErrorMessageToSend 
  -- Send SMS
  -- put here code to send SMS
  --Change Status
  set @DBNAME = CAST(DB_NAME(@DB_ID) as VARCHAR)
  exec ('Alter database ' + @dbname + ' set partner resume')
	
   DELETE FROM @MirroredDatabases WHERE DatabaseID = @DB_ID 
END