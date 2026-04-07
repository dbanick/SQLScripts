USE [master]
GO
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON ;

    -- Insert statements for procedure here
        DECLARE @Time_Start DATETIME ;
        DECLARE @Time_End DATETIME ;
        DECLARE @Version CHAR(4) ;
        SET @Time_Start = GETDATE() - 30 ;
        SET @Time_End = GETDATE() ;
        SET @Version = RIGHT(RTRIM(LEFT(@@VERSION, 26)), 4) ;

          CREATE TABLE #BackupSuccess
            (LogDate DATETIME,
             ProcessInfo NVARCHAR(40),
             [Text] NVARCHAR(3000),
             [Database] NVARCHAR(100),
             BackupType NVARCHAR(10))
             
             
        IF @Version = '2000' 
            BEGIN
                        
               CREATE TABLE #ErrorLog
                    ([Text] NVARCHAR(255),
                     ContinuationRow INT)

                INSERT  INTO #ErrorLog
                        ([Text], ContinuationRow)
                        EXEC master.dbo.xp_readerrorlog 

                INSERT  INTO #ErrorLog
                        ([Text], ContinuationRow)
                        EXEC master.dbo.xp_readerrorlog 1

                INSERT  INTO #ErrorLog
                        ([Text], ContinuationRow)
                        EXEC master.dbo.xp_readerrorlog 2

                INSERT  INTO #ErrorLog
                        ([Text], ContinuationRow)
                        EXEC master.dbo.xp_readerrorlog 3

        /*INSERT  INTO #ErrorLog
                ([Text], ContinuationRow)
                EXEC master.dbo.xp_readerrorlog 4

        INSERT  INTO #ErrorLog
                ([Text], ContinuationRow)
                EXEC master.dbo.xp_readerrorlog 5*/

               
                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        SELECT  LogDate, ProcessInfo, NewText
                        FROM    (SELECT CONVERT(DATETIME, LEFT([Text], 22)) AS LogDate,
                                        LTRIM(RTRIM(SUBSTRING([Text], 23, 10))) AS ProcessInfo,
                                        RIGHT([Text], 222) AS NewText
                                 FROM   #ErrorLog
                                 WHERE  ISDATE(LEFT([Text], 22)) = 1
                                        AND ContinuationRow = 0) Filter
                        WHERE   ProcessInfo = 'backup'
                                AND LogDate BETWEEN @Time_Start AND @Time_End
                                AND (LEFT(NewText, 8) = 'Database'
                                     OR LEFT(NewText, 3) = 'Log')
                        ORDER BY LogDate

           
                UPDATE  #BackupSuccess
                SET     BackupType = CASE WHEN LEFT([Text], 21) = 'Database differential' THEN 'Diff'
                                          WHEN LEFT([Text], 18) = 'Database backed up' THEN 'Full'
                                          WHEN LEFT([Text], 13) = 'Log backed up' THEN 'Tx Log'
                                          ELSE NULL
                                     END,
                        [Database] = SUBSTRING([Text], (CHARINDEX('Database:', [Text]) + 10),
                                               (CHARINDEX(',', [Text])) - ((CHARINDEX('Database:', [Text]) + 10)))

                DROP TABLE #ErrorLog

            END

        IF @Version = '2005' 
           begin

              
                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        EXEC master.dbo.xp_readerrorlog 0, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        EXEC master.dbo.xp_readerrorlog 1, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        EXEC master.dbo.xp_readerrorlog 2, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        EXEC master.dbo.xp_readerrorlog 3, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

        /*INSERT  INTO #BackupSuccess
                (LogDate, ProcessInfo, [Text])
                EXEC master.dbo.xp_readerrorlog 4, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

        INSERT  INTO #BackupSuccess
                (LogDate, ProcessInfo, [Text])
                EXEC master.dbo.xp_readerrorlog 5, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;*/

               
                UPDATE  #BackupSuccess
                SET     BackupType = CASE WHEN LEFT([Text], 44) = 'Database differential changes were backed up'
                                          THEN 'Diff'
                                          WHEN LEFT([Text], 18) = 'Database backed up' THEN 'Full'
                                          WHEN LEFT([Text], 17) = 'Log was backed up' THEN 'Tx Log'
                                          ELSE NULL
                                     END,
                        [Database] = CASE WHEN LEFT([Text], 44) = 'Database differential changes were backed up'
                                          THEN LTRIM(RTRIM(SUBSTRING([Text], 57,
                                                                     PATINDEX('%, creation date(time):%', [Text]) - 57)))
                                          WHEN LEFT([Text], 18) = 'Database backed up'
                                          THEN LTRIM(RTRIM(SUBSTRING([Text], 31,
                                                                     PATINDEX('%, creation date(time):%', [Text]) - 31)))
                                          WHEN LEFT([Text], 17) = 'Log was backed up'
                                          THEN LTRIM(RTRIM(SUBSTRING([Text], 30,
                                                                     PATINDEX('%, creation date(time):%', [Text]) - 30)))
                                          ELSE NULL
                                     END ;

            END

        IF @Version = '2008' 
            BEGIN

                
                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        EXEC master.dbo.xp_readerrorlog 0, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        EXEC master.dbo.xp_readerrorlog 1, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        EXEC master.dbo.xp_readerrorlog 2, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

                INSERT  INTO #BackupSuccess
                        (LogDate, ProcessInfo, [Text])
                        EXEC master.dbo.xp_readerrorlog 3, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

        /*INSERT  INTO #BackupSuccess
                (LogDate, ProcessInfo, [Text])
                EXEC master.dbo.xp_readerrorlog 4, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;

        INSERT  INTO #BackupSuccess
                (LogDate, ProcessInfo, [Text])
                EXEC master.dbo.xp_readerrorlog 5, 1, 'backed up', NULL, @Time_Start, @Time_End, N'asc' ;*/

                UPDATE  #BackupSuccess
                SET     BackupType = CASE WHEN LEFT([Text], 44) = 'Database differential changes were backed up'
                                          THEN 'Diff'
                                          WHEN LEFT([Text], 18) = 'Database backed up' THEN 'Full'
                                          WHEN LEFT([Text], 17) = 'Log was backed up' THEN 'Tx Log'
                                          ELSE NULL
                                     END,
                        [Database] = CASE WHEN LEFT([Text], 44) = 'Database differential changes were backed up'
                                          THEN LTRIM(RTRIM(SUBSTRING([Text], 57,
                                                                     PATINDEX('%, creation date(time):%', [Text]) - 57)))
                                          WHEN LEFT([Text], 18) = 'Database backed up'
                                          THEN LTRIM(RTRIM(SUBSTRING([Text], 31,
                                                                     PATINDEX('%, creation date(time):%', [Text]) - 31)))
                                          WHEN LEFT([Text], 17) = 'Log was backed up'
                                          THEN LTRIM(RTRIM(SUBSTRING([Text], 30,
                                                                     PATINDEX('%, creation date(time):%', [Text]) - 30)))
                                          ELSE NULL
                                     END

            END

       
           
SELECT  
[Database],max(LogDate) BackupCompleteDate,BackupType 
FROM #BackupSuccess
where LogDate >=DATEADD(hh,-24,GETDATE())
group by [Database],BackupType
order by [Database],BackupType

     
DROP TABLE #BackupSuccess
