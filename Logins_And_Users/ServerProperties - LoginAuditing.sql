declare @AuditLevel int
exec master..xp_instance_regread 
    @rootkey='HKEY_LOCAL_MACHINE',
    @key='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
    @value_name='AuditLevel',
    @value=@AuditLevel output
select @@SERVERNAME as ServerName, 
CASE WHEN @AuditLevel = 0 THEN 'None'
WHEN @AuditLevel = 1 THEN 'Successful Logins Only'
WHEN @AuditLevel = 2 THEN 'Failed Logins Only'
WHEN @AuditLevel = 3 THEN 'Both Failed and Successful Logins'
END as AuditLevel