--Changes to make
--update Email profile/account and Recipients --line 147 & 148
--create whoisactiveLogging process
--create AlertLog table
--change database name if we aren't using DBAdmin database for storing whoisactive info (find + replace DBAdmin with master or other database you are using)
-- Create a temporary table to store the latest blocking information 
CREATE TABLE ##LatestBlocking (
	[dd hh:mm:ss.mss] NVARCHAR(50)
	,WaitTime INT
	,blocker_session_id INT
	,blocker_sql_text NVARCHAR(MAX)
	,blocker_login_name NVARCHAR(128)
	,blocker_wait_info NVARCHAR(MAX)
	,blocker_host_name NVARCHAR(128)
	,blocker_database_name NVARCHAR(128)
	,blocker_program_name NVARCHAR(128)
	,rn INT
	);

-- Insert data into the temporary table, filtering for the specific database 
INSERT INTO ##LatestBlocking
SELECT a.[dd hh:mm:ss.mss]
	,CONVERT(INT, SUBSTRING(a.wait_info, 2, CHARINDEX('ms)', a.wait_info) - 2)) AS WaitTime
	,b.[session_id] AS blocker_session_id
	,CONVERT(NVARCHAR(MAX), b.[sql_text]) AS blocker_sql_text
	,b.[login_name] AS blocker_login_name
	,CONVERT(NVARCHAR(MAX), b.[wait_info]) AS blocker_wait_info
	,b.[host_name] AS blocker_host_name
	,b.[database_name] AS blocker_database_name
	,-- Check the database name here 
	b.[program_name] AS blocker_program_name
	,ROW_NUMBER() OVER (
		PARTITION BY a.[blocking_session_id] ORDER BY a.[collection_time] DESC
		) AS rn
FROM [DBAdmin].[dbo].[WhoisactiveLogging] a
JOIN [DBAdmin].[dbo].[WhoisactiveLogging] b ON a.[blocking_session_id] = b.[session_id]
WHERE a.[blocking_session_id] IS NOT NULL
	AND CONVERT(INT, SUBSTRING(a.wait_info, 2, CHARINDEX('ms)', a.wait_info) - 2)) > 120000
	AND a.[collection_time] >= DATEADD(minute, - 5, GETDATE());
	-- Add this condition to filter for the desired database 
	-- Query the temporary table to get the latest blocking information 

SELECT [dd hh:mm:ss.mss]
	,WaitTime
	,[blocker_session_id]
	,[blocker_sql_text]
	,[blocker_login_name]
	,[blocker_wait_info]
	,[blocker_host_name]
	,[blocker_database_name]
	,[blocker_program_name]
FROM ##LatestBlocking
WHERE rn = 1;

-- Check for lead blockers and send email if necessary 
IF EXISTS (
		SELECT 1
		FROM ##LatestBlocking l
		WHERE NOT EXISTS (
				SELECT 1
				FROM [DBAdmin].[dbo].[AlertLog] al
				WHERE al.BlockerSessionID = l.blocker_session_id
					AND al.AlertTime >= DATEADD(hour, - 1, GETDATE())
				)
			AND EXISTS (
				SELECT 1
				FROM [DBAdmin].[dbo].[WhoisactiveLogging] c
				WHERE c.blocking_session_id = l.blocker_session_id
					AND c.blocking_session_id IS NOT NULL
				)
		)
BEGIN
	SELECT 'Email Blocking Report'   /* 
      Declare Variables for HTML 
      */
		      DECLARE @Style NVARCHAR(MAX) = '';

	       /* 
      Define CSS for html to use 
      */
		      SET @Style += + N'<style type="text/css"> 
.tg {border-collapse:collapse;border-color:#9ABAD9;border-spacing:0;} 
.tg td{background-color:#EBF5FF;border-color:#9ABAD9;border-style:solid;border-width:0px;color:#444; 
  font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;word-break:normal;} 
.tg th{background-color:#409cff;border-color:#9ABAD9;border-style:solid;border-width:0px;color:#fff; 
  font-family:Arial, sans-serif;font-size:14px;font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;} 
.tg .tg-fymr{border-color:inherit;font-weight:bold;text-align:left;vertical-align:top} 
.tg .tg-0pky{border-color:inherit;text-align:left;vertical-align:top} 
</style>';

	       /* 
      Declare Variables for HTML 
      */
		      DECLARE @tableHTML NVARCHAR(MAX) = '';

	      SET @tableHTML += @Style + @tableHTML + N'<H2>Blocking Report </H2>'              + N'<table class="tg"><thead>Here are all the lead blockers: 
 <tr> 
<th class="tg-fymr">Duration - [dd hh:mm:ss.mss]</th> 
<th class="tg-fymr">WaitTime</th> 
<th class="tg-fymr">blocker_session_id</th> 
<th class="tg-fymr">blocker_sql_text</th> 
<th class="tg-fymr">blocker_login_name</th> 
<th class="tg-fymr">blocker_wait_info</th> 
<th class="tg-fymr">blocker_host_name</th> 
<th class="tg-fymr">blocker_database_name</th> 
<th class="tg-fymr">blocker_program_name</th> 
 </tr></thead>' --DEFINE TABLE 
		       /* 
      Define data for table and cast to xml 
      */
		             + CAST((
				SELECT td = [dd hh:mm:ss.mss]
					,     ''
					,                                    td = isnull(WaitTime, '')
					,       ''
					,                                    td = isnull([blocker_session_id], '')
					,''
					,                                    td = isnull([blocker_sql_text], '')
					,    ''
					,                                    td = isnull([blocker_login_name], '')
					,   ''
					,                                    td = isnull([blocker_wait_info], '')
					,''
					,                                    td = isnull([blocker_host_name], '')
					,''
					,                                    td = isnull([blocker_database_name], '')
					,''
					,                                    td = isnull([blocker_program_name], '')
					,''                         
				FROM ##LatestBlocking l
				WHERE rn = 1
					AND NOT EXISTS (
						SELECT al.blockerSessionId
						FROM [DBAdmin].[dbo].[AlertLog] al
						WHERE al.BlockerSessionID = l.blocker_session_id
							AND al.AlertTime >= DATEADD(hour, - 1, GETDATE())
						)                   
				FOR                          XML PATH('tr')
					,                               TYPE                   
				) AS NVARCHAR(MAX)) + N'</table>';

	       --check html       
		       --select @tableHTML 
		-- Send alert via database mail 

	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Alerting @OrbiMed.com SMTP Relay'
		,@recipients = 'tradingdevelopment@orbimed.com; nick.patti@datastrike.com; lucja.dolega@datastrike.com'
		,-- 
		@subject = 'Blocking Alert'
		,@body = @tableHTML
		,        @body_format = 'HTML'

	-- Log the alert to prevent duplicates 
	INSERT INTO [DBAdmin].[dbo].[AlertLog] (
		BlockerSessionID
		,AlertTime
		)
	SELECT blocker_session_id
		,GETDATE()
	FROM ##LatestBlocking;
END
ELSE
	SELECT 'No Blocking to report'

-- Drop the temporary table 
DROP TABLE ##LatestBlocking;