--https://www.brentozar.com/blitz/trace-flags-enabled-globally/

CREATE TABLE #results
    (
	  [TraceFlag] int, [Status] int, [Global] int, [Session] int
    );

            INSERT INTO #results 
            exec sp_executesql N'DBCC TRACESTATUS (-1)';
SELECT  @@SERVERNAME AS [Server Name], *
FROM    #results
DROP TABLE #results;