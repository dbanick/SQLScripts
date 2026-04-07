--Job starts another job only if it is Sunday and not the 13th.  If Sunday =13th, it runs Monday night instead

USE [msdb] 

DECLARE @currentDay int 
DECLARE @yesterdayWeekDay varchar(15) 
DECLARE @todayWeekDay varchar(15) 
DECLARE @normalRunDay varchar(15) 
SET @currentDay = (select datepart(day, GETDATE())) 
SET @yesterdayWeekDay = (select DATENAME(weekday,GETDATE() -1)) 
SET @todayWeekDay = (select DATENAME(weekday,GETDATE())) 
SET @normalRunDay = 'Sunday' --the normally scheduled run day 

--if today is not the 13th and today is the normal run day, start job 
if @currentDay != 13 and @todayWeekDay = @normalRunDay 
exec sp_start_job @job_name ='Weekly Index Rebuilds & Update Stats.Subplan_1' 
else print 'Today is the 13th and job has been skipped' 

--if today is the 14th and yesterday was the normal run day, 
--it did not run yesterday(13th)and needs to run today 
if @currentDay =14 and @yesterdayWeekDay = @normalRunDay 
exec sp_start_job @job_name ='Weekly Index Rebuilds & Update Stats.Subplan_1' 
else print 'The job should have ran yesterday' 