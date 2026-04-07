--This query will check for blocking or long running transactions
--it can also send an email with the blocking info or LRT information

SET NOCOUNT ON
 
DECLARE @Hours int
DECLARE @EmailReport bit 
set @emailreport=0 
--By default this will look for anything older than 24 hours
SET @Hours = 24
 
-- Set to 1 to output a report for email
SET @EmailReport = 1
 
 
 
CREATE TABLE #BlockProcs 
                (
                [SPID] int ,
                [Status] varchar(1000),
                [Login] varchar(1000),
                [HostName] varchar(100),
                [BlkBy] int,
                [DBName] varchar(1000),
                [Command] varchar(1000),
                [CPUTIME] varchar(100),
                [DISKIO] varchar(100),
                [LASTBATCH] datetime,
                [PROGRAMNAME] varchar(1000),
                [DBCC INPUTBUFFER] nvarchar(4000)               
                )
                
CREATE TABLE #LRTProcs 
                (
                [SPID] int ,
                [Status] varchar(1000),
                [Login] varchar(1000),
                [HostName] varchar(100),
                [BlkBy] int,
                [DBName] varchar(1000),
                [Command] varchar(1000),
                [CPUTIME] varchar(100),
                [DISKIO] varchar(100),
                [LASTBATCH] datetime,
                [PROGRAMNAME] varchar(1000),
                [DBCC INPUTBUFFER] nvarchar(4000)               
                )
                
CREATE TABLE #ibufftmp 
                (
                [EventType] nvarchar(30),
                [Parameters] smallint,
                [DBCC INPUTBUFFER] nvarchar(4000)
                )
 
DECLARE @Debug int 
set @debug= 0
DECLARE @counter int
DECLARE @end int
DECLARE @batch datetime
DECLARE @date datetime
DECLARE @oldestbatch datetime
DECLARE @dbcc varchar(5000)
DECLARE @server varchar(5000)                                                               
 
-- Capture current processes
INSERT INTO #BlockProcs ([SPID],[Status],[Login],[HostName],[BlkBy],[DBName],[Command],[CPUTIME],[DISKIO],[LASTBATCH],[PROGRAMNAME])
                SELECT spid, upper(status),loginame,hostname,blocked,db_name(dbid),cmd,cpu,physical_io,last_batch, program_name FROM master..sysprocesses WHERE spid >= 50
                
INSERT INTO #LRTProcs ([SPID],[Status],[Login],[HostName],[BlkBy],[DBName],[Command],[CPUTIME],[DISKIO],[LASTBATCH],[PROGRAMNAME])
                SELECT spid, upper(status),loginame,hostname,blocked,db_name(dbid),cmd,cpu,physical_io,last_batch, program_name FROM master..sysprocesses WHERE spid >= 50
 
--Remove processes not involved with blocking
IF @Debug = 1
                SELECT * FROM #BlockProcs WHERE SPID not in (select BlkBy from #BlockProcs where BlkBy <> 0) AND BlkBy = 0
 
DELETE FROM #BlockProcs WHERE SPID not in (select BlkBy from #BlockProcs where BlkBy <> 0) AND BlkBy = 0
                                
IF @Debug = 1
                SELECT * FROM #BlockProcs       
                                                                
--PRINT SERVER NAME
SELECT @Server = @@SERVERNAME
--SELECT 'Server : ' + cast(@Server as varchar(255))+CHAR(10)+' '+CHAR(10)+' ' as ' '
--PRINT CHAR(10)
 
 
SELECT 'BlockerProcs' as ' '
 
IF (select COUNT(*) from #BlockProcs) = 0
                BEGIN
                                SELECT 'No Blocking on Server'  as ' '
                END
  ELSE
                BEGIN
                                DECLARE Blocker CURSOR FOR SELECT distinct SPID from #BlockProcs order by SPID
                                OPEN Blocker
 
                                FETCH NEXT FROM Blocker INTO @counter
                                WHILE @@FETCH_STATUS = 0
                                                BEGIN
                                                                                                                
                                                                                SET @dbcc = 'DBCC INPUTBUFFER(' + cast(@counter as varchar(10)) + ') WITH NO_INFOMSGS' 
                                                                                                
                                                                                TRUNCATE TABLE #ibufftmp
                                                                                INSERT INTO #ibufftmp
                                                                                                EXEC(@dbcc)                     
                                                                                                                                
                                                                                UPDATE #BlockProcs
                                                                                                SET [DBCC INPUTBUFFER] = (SELECT [DBCC INPUTBUFFER] FROM #ibufftmp)
                                                                                                WHERE SPID = @counter
                                                                                                                                                                
                                                                                                
                                                -- Fetch next spid
                                                                FETCH NEXT FROM Blocker INTO @counter
                                                END
                                                                
                -- Close the cursor 
                CLOSE Blocker
                DEALLOCATE Blocker
                
                IF @Debug = 1
                                SELECT * FROM #BlockProcs
 
 
                -- Email Report
                SELECT *
                FROM #BlockProcs 
                ORDER BY [BlkBy], [SPID]
 
 
                END       
                                
                                
 
SELECT 'LongRunningTrans' as ' '                                
-- Remove spids that are not executing and their LASTBATCH < @Hours
DELETE FROM #LRTProcs 
                WHERE DATEDIFF(HH,[LASTBATCH],GETDATE()) < @Hours 
                OR  -- Remove non-active procs
                                ( 
                                [Status] = 'sleeping'
                                AND
                                [Command] IN ('AWAITING COMMAND','LAZY WRITER','CHECKPOINT SLEEP')
                                AND
                                [BlkBy] = 0
                                )
 
--IF OLDEST TRANSACTION IS NOT 24 HOURS OLD, PRINT TO SCREEN
IF (SELECT COUNT(*) FROM #LRTProcs) = 0
                BEGIN
                                SELECT 'No transactions running longer than '+CONVERT(varchar(10),@Hours)+' hours' as ' '
                END
                ELSE 
                BEGIN
                                DECLARE LRT CURSOR FOR SELECT distinct SPID from #LRTProcs
                                OPEN LRT
 
                                FETCH NEXT FROM LRT INTO @counter
                                WHILE @@FETCH_STATUS = 0          
                                                BEGIN
                                                                SET @dbcc = 'DBCC INPUTBUFFER(' + cast(@counter as varchar(10)) + ') WITH NO_INFOMSGS' 
                                                                                                                
                                                                TRUNCATE TABLE #ibufftmp
                                                                INSERT INTO #ibufftmp
                                                                                exec(@dbcc)                     
 
                                                                UPDATE #LRTProcs
                                                                                SET [DBCC INPUTBUFFER] = (SELECT [DBCC INPUTBUFFER] FROM #ibufftmp)
                                                                                WHERE [SPID] = @counter
                                                                                                                                                                
                                                                FETCH NEXT FROM LRT INTO @counter
                                                END  
                                                                                                
                                CLOSE LRT
                                DEALLOCATE LRT
 
 
                                SELECT *
                                                FROM #LRTProcs
                                                ORDER BY [SPID]
                END
 
IF @EmailReport = 1
                BEGIN
                                SELECT 'Email Report' as ' '                            
                                SELECT 'Server : ' + cast(@Server as varchar(255))+CHAR(10)+' '+CHAR(10)+' ' as ' '
                                UNION ALL
                                SELECT 'Blockers'+CHAR(10)+'-----------------------------------------' as ' '
                                UNION ALL
                                SELECT  CHAR(10)+'sp_who2'
                                                                +CHAR(10)+
                                                                RTRIM(CONVERT(varchar(10),[SPID]))+' '+RTRIM([Status])+' '+RTRIM([Login])+' '+RTRIM([HostName])+' . '+RTRIM([DBName])+' ' +RTRIM([Command])+' '+RTRIM([CPUTIME])+' '+RTRIM([DISKIO])+' '+RTRIM(CONVERT(varchar(30),[LASTBATCH],100))+' '+RTRIM([PROGRAMNAME])
                                                                +CHAR(10)+' '+
                                                                +CHAR(10)
                                                                FROM #BlockProcs 
                                                                WHERE [BlkBy] = 0
                                UNION ALL 
                                SELECT 'dbcc inputbuffer('+CONVERT(varchar(10),[SPID])+')'+CHAR(10)+
                                                                ISNULL([DBCC INPUTBUFFER],'NULL')
                                                                +CHAR(10)+' '+
                                                                +CHAR(10)+' '
                                                                as ' '
                                                FROM #BlockProcs 
                                                                WHERE [BlkBy] = 0
                                UNION ALL
                                                SELECT 'Blocked'+CHAR(10)+'-----------------------------------------' as ' '
                                UNION ALL
                                SELECT  CHAR(10)+'sp_who2'
                                                                +CHAR(10)+
                                                                RTRIM(CONVERT(varchar(10),[SPID]))+' '+RTRIM([Status])+' '+RTRIM([Login])+' '+RTRIM([HostName])+' '+RTRIM(CONVERT(varchar(10),[BlkBy]))+' '+RTRIM([DBName])+' ' +RTRIM([Command])+' '+RTRIM([CPUTIME])+' '+RTRIM([DISKIO])+' '+RTRIM(CONVERT(varchar(30),[LASTBATCH],100))+' '+RTRIM([PROGRAMNAME])
                                                                +CHAR(10)+' '+
                                                                +CHAR(10)
                                                                FROM #BlockProcs 
                                                                WHERE [BlkBy] <> 0
                                UNION ALL 
                                SELECT 'dbcc inputbuffer('+CONVERT(varchar(10),[SPID])+')'+CHAR(10)+
                                                                ISNULL([DBCC INPUTBUFFER],'NULL')
                                                                +CHAR(10)+' '+
                                                                +CHAR(10)+' '
                                                                as ' '
                                                FROM #BlockProcs 
                                                                WHERE [BlkBy] <> 0
                                UNION ALL
                                SELECT 'Old Spids'+CHAR(10)+'-----------------------------------------'+CHAR(10) as ' '
                                UNION ALL
                                SELECT  CHAR(10)+'sp_who2'
                                                +CHAR(10)+
                                                RTRIM(CONVERT(varchar(10),[SPID]))+' '+RTRIM([Status])+' '+RTRIM([Login])+' '+RTRIM([HostName])+' '+RTRIM(CONVERT(varchar(10),[BlkBy]))+' '+RTRIM([DBName])+' ' +RTRIM([Command])+' '+RTRIM([CPUTIME])+' '+RTRIM([DISKIO])+' '+RTRIM(CONVERT(varchar(30),[LASTBATCH],100))+' '+RTRIM([PROGRAMNAME])
                                                +CHAR(10)+' '+
                                                +CHAR(10)+
                                                'dbcc inputbuffer('+CONVERT(varchar(10),[SPID])+')'+CHAR(10)+
                                                ISNULL([DBCC INPUTBUFFER],'NULL')
                                                +CHAR(10)+' '+
                                                +CHAR(10)+' '
                                                as ' '
                                FROM #LRTProcs
                END
 
 
GO
DROP TABLE #BlockProcs
GO
DROP TABLE #ibufftmp
GO
DROP TABLE #LRTProcs
GO
