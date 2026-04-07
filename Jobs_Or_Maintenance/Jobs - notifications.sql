SELECT	 @@SERVERNAME as ServerName
		,[JobName] = [jobs].[name]
		,[Category] = [categories].[name]
		,[Owner] = SUSER_SNAME([jobs].[owner_sid])
		,[Enabled] = CASE [jobs].[enabled] WHEN 1 THEN 'Yes' ELSE 'No' END
		,[Scheduled] = CASE [schedule].[enabled] WHEN 1 THEN 'Yes' ELSE 'No' END
		,[Notify Level] = CASE [jobs].[notify_level_email] WHEN 1 then 'On Success' WHEN 2 then 'On Failure' WHEN 3 then 'On Completion' ELSE 'Notification not set' END
		,e.name AS EmailOperator
FROM	 [msdb].[dbo].[sysjobs] AS [jobs] WITh(NOLOCK) 
LEFT JOIN msdb.dbo.sysoperators e 
     on jobs.notify_email_operator_id = e.id
		 LEFT OUTER JOIN [msdb].[dbo].[sysjobschedules] AS [jobschedule] WITh(NOLOCK) 
				 ON [jobs].[job_id] = [jobschedule].[job_id] 
		 LEFT OUTER JOIN [msdb].[dbo].[sysschedules] AS [schedule] WITh(NOLOCK) 
				 ON [jobschedule].[schedule_id] = [schedule].[schedule_id] 
		 INNER JOIN [msdb].[dbo].[syscategories] [categories] WITh(NOLOCK) 
				 ON [jobs].[category_id] = [categories].[category_id] 
GO

