--Returns information about subscriptions in ReportServer
SELECT
c .Name AS ReportName
, rs . ScheduleID AS JOB_NAME
, s . [Description]
, s . LastStatus
, s . LastRunTime
FROM
ReportServer ..[Catalog] c
JOIN ReportServer .. Subscriptions s ON c. ItemID = s. Report_OID
JOIN ReportServer .. ReportSchedule rs ON c. ItemID = rs. ReportID
AND rs . SubscriptionID = s . SubscriptionID
order by lastruntime desc 