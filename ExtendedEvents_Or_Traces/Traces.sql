--fn_trace_gettable used to pull data from trace and load into a table

-- Example #1 - Find distinct logins from trace
SELECT DISTINCT Hostname, applicationname, loginname, databasename
FROM fn_trace_gettable('\\10.1.100.153\MSSQL_Share2\LoginTrace\P111SQLV13\P111SQLI13\TraceFiles\DurationLoginAudithostname.trc', default)
where applicationname not like 'SQLAgent%'
GO

-- Example #2 - Find timeouts during a specified window
USE DBA
GO
SELECT TextData, NTUserName, ApplicationName, LoginName, HostName, (Duration/1000) as duration, StartTime, EndTime, Reads, Writes, CPU, DatabaseName INTO trc_hostname
FROM fn_trace_gettable('E:\Trace\Duration10sMore_2016_04_07_164725_210_10Seconds.trc', default)
where duration between 29900000 and 31000000
AND DATEPART(hh,StartTime) >= 6 AND DATEPART(hh,StartTime) <= 12
and ApplicationName not like 'REPL%'
and ApplicationName not like 'SQLAgent%'
AND Hostname like 'PBTPSEA%'
GO


--use this query to make loading results into excel easier
/*
select LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(substring(TextData, 0, 120) ,CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' '))) as TextData , ApplicationName, substring(LoginName,2,100) as LoginName, Hostname, duration, StartTime, EndTime, Reads, Writes, CPU, DatabaseName from DBA.dbo.trc_hostname
*/