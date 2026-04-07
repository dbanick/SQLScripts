/*
--Purpose:  To script all SQL Alerts, so the the resulting script can be applied to add alerts on to another server
--Author:	Carolyn Richardson
--Date:		13/05/2014
*/


--Run on source server
USE MSDB
GO

SELECT 'IF (EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'''+NAME+'''))
 ---- Delete the alert with the same name.
  EXECUTE msdb.dbo.sp_delete_alert @name = N'''+name+''' 
BEGIN 
EXECUTE msdb.dbo.sp_add_alert @name = N'''+name+''', @message_id = '+CAST(message_id AS VARCHAR(10))+' , @severity = '+CAST(severity AS VARCHAR(10))+' , @enabled = 1, @delay_between_responses = '+CAST(delay_between_responses AS VARCHAR(10))+' , @include_event_description_in = '+CAST(include_event_description AS VARCHAR(10))+', @category_name = N''[Uncategorized]''
END
' FROM [msdb].[dbo].[sysalerts]
WHERE category_id <> 20


--Add email notifications amend DBA to your operator
SELECT 'EXEC msdb.dbo.sp_add_notification @alert_name=N'''+NAME+''', @operator_name=N''DBA'', @notification_method = 7;'
FROM [msdb].[dbo].[sysalerts]
WHERE category_id <> 20

--Run results on destination server