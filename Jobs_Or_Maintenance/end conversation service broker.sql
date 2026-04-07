--checks service broker for service name and generates command to end the conversation with cleanup
declare @conversation uniqueidentifier
declare @sql varchar(250)

while (select count(1) from sys.transmission_queue where to_service_name = 'QS_DeadlockService') >= 1
BEGIN
	set @conversation = (select top 1 conversation_handle from sys.transmission_queue where to_service_name = 'QS_DeadlockService')
	SET @SQL = 'end conversation ''' + cast(@conversation as varchar(200)) + '''  with cleanup'
	select(@SQL)
	exec(@SQL)
	WAITFOR DELAY '00:00:15'

END