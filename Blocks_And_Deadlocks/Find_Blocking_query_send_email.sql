--This query will check for blocking. 
--It is setup to search for blocking caused by a specific Login, with a specific query text that has been blocking over X minutes
--if that blocking is found, it will kill the query.
--it can also send an email with the blocking info
--the kill portion can be disabled so it will alert/email only

SET NOCOUNT ON
 
DECLARE @minutes int
DECLARE @EmailReport bit 
DECLARE @Debug int 
DECLARE @recipients varchar(500), @profile varchar(500)
DECLARE @kill bit

set @kill = 0
set @debug= 0

-- Set to 1 to output a report for email
set @emailreport=1 
set @recipients = 'lucja.dolega@datastrike.com'
set @profile = 'email'

--By default this will look for anything older than x minutes
SET @minutes = 1
 
 
CREATE TABLE #BlockProcs 
                (
                [SPID] int ,
                [Status] varchar(100),
                [Login] varchar(100),
                [HostName] varchar(100),
                [BlkBy] int,
                [DBName] varchar(100),
                [Command] varchar(100),
                [CPUTIME] varchar(100),
                [DISKIO] varchar(100),
                [LASTBATCH] datetime,
                [PROGRAMNAME] varchar(100),
                [DBCC INPUTBUFFER] nvarchar(4000)               
                )
                
CREATE TABLE #ibufftmp 
                (
                [EventType] nvarchar(30),
                [Parameters] smallint,
                [DBCC INPUTBUFFER] nvarchar(4000)
                )
 

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
                                SELECT * FROM #BlockProcs ORDER BY [BlkBy], [SPID]
 
 
                END       
                                
                                
--Check if its still blocking
IF EXISTS (SELECT 1 FROM #BlockProcs WHERE  BlkBy = 0 and LASTBATCH < DATEADD(MINUTE, - @minutes, GETDATE()) 
			)
BEGIN
	DECLARE @QKILLsp VARCHAR(1000)

	SET @QKILLsp= (SELECT DISTINCT '  KILL '+ CONVERT(VARCHAR,SPID)
							FROM #BlockProcs I
							WHERE   BlkBy = 0 and LASTBATCH < DATEADD(MINUTE, - @minutes, GETDATE())
							
							for XML path('')
							)
								
	--EXEC(@QKILLsp) 
	
	
	IF @Debug = 1
				BEGIN
				select(@QKILLsp)
				END
		IF @EmailReport = 1
						BEGIN

						IF @Debug = 1
						BEGIN
							-- Email Report
							SELECT *
							FROM #BlockProcs 
							ORDER BY [BlkBy], [SPID]
						END


						Declare @Body varchar(max), @TableHead varchar(1000), @TableTail varchar(1000)
						Set NoCount On;


						Set @TableTail = '</table>
						<br />
												 <br />
						 The below query is causing blocking and is open for ' + cast(@minutes as varchar(10))+ ' minutes.
						</body></html>';
						Set @TableHead = '<html><head>' +
											'<style>' +
											'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} ' +
											'</style>' +
											'</head>' +
											'<body><table cellpadding=0 cellspacing=0 border=0>' +
											'<tr><td align=center bgcolor=#E6E6FA><b>SPID</b></td>' +
											'<td align=center bgcolor=#E6E6FA><b>Event Info</b></td>' +
											'<td align=center bgcolor=#E6E6FA><b>Login</b></td>'+
											'<td align=center bgcolor=#E6E6FA><b>DBName</b></td>'+
											'<td align=center bgcolor=#E6E6FA><b>Command</b></td>'+
											'<td align=center bgcolor=#E6E6FA><b>Blocked By</b></td>'+
											'<td align=center bgcolor=#E6E6FA><b>LastBatch</b></td></tr>';

						Select @Body = (		SELECT
												td= I.SPID,'',
												td= I.[DBCC INPUTBUFFER],'',		
												td= MAX(I.Login),'',
												td= I.DBName,'',
												td= I.Command,'',
												td= I.BlkBY, '',
												td= I.LastBatch,''		
												FROM  #BlockProcs I
												GROUP BY SPID, [DBCC INPUTBUFFER], DBName, Command, BlkBy, LastBatch
												For XML raw('tr'), Elements
												)

				

						-- Replace the entity codes and row numbers
						Set @Body = Replace(@Body, '_x0020_', space(1))
						Set @Body = Replace(@Body, '_x003D_', '=')
						Set @Body = Replace(@Body, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#C6CFFF>')
						Set @Body = Replace(@Body, '<TRRow>0</TRRow>', '')


							Select @Body = @TableHead + @Body + @TableTail

							IF @Debug = 1
							select @body

							-- Send mail to DBA Team
							EXEC msdb.dbo.sp_send_dbmail @recipients= @recipients, -- change mail address accordingly
								@subject = 'Blocking Session Detected', 
								@profile_name = @profile, -- Change profile name accordingly
								@body = @Body,
								@body_format = 'HTML' ;



						END
END

 
GO
DROP TABLE #BlockProcs
GO
DROP TABLE #ibufftmp
GO
