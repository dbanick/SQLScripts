--Create common alerts


EXEC msdb.dbo.sp_add_alert @name=N'19 - Fatal Error in Resource',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1


GO


EXEC msdb.dbo.sp_add_alert @name=N'20 - Fatal Error in Current Process',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1


GO


EXEC msdb.dbo.sp_add_alert @name=N'21 - Fatal Error in Database Processes',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1


GO

EXEC msdb.dbo.sp_add_alert @name=N'22 - Fatal Error - Table Integrity Suspect',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1


GO


EXEC msdb.dbo.sp_add_alert @name=N'23 - Fatal Error - Database Integrity Suspect',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1


GO


EXEC msdb.dbo.sp_add_alert @name=N'24 - Fatal Error - Hardware Error ',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1


GO


EXEC msdb.dbo.sp_add_alert @name=N'25 - Fatal Error',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1


USE msdb



GO



EXEC msdb.dbo.sp_add_alert @name = N'823 - Read/Write Failure', 
    @message_id = 823,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1


GO
EXEC msdb.dbo.sp_add_alert @name = N'824 - Page Error', 
    @message_id = 824,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1


GO



EXEC msdb.dbo.sp_add_alert @name = N'825 - Read-Retry Required', 
    @message_id = 825,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 60,
    @include_event_description_in = 1


GO


EXEC msdb.dbo.sp_add_alert @name=N'829- Page RestorePending', 
  @message_id=829, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses = 60,
  @include_event_description_in = 1


GO


EXEC msdb.dbo.sp_add_alert @name=N'832- Memory Error', 
  @message_id=832, 
  @severity=0, 
  @enabled=1, 
  @delay_between_responses = 60,
  @include_event_description_in = 1

GO
