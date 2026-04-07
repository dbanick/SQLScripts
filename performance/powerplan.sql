DECLARE
@value VARCHAR(64),
@key VARCHAR(512) = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\'
+ 'ControlPanel\NameSpace\{025A5937-A6BE-4686-A844-36FE4BEC8B6D}';

EXEC master..xp_regread
@rootkey = 'HKEY_LOCAL_MACHINE',
@key = @key,
@value_name = 'PreferredPlan',
@value = @value OUTPUT;

SELECT @@SERVERNAME as ServerName, 
CASE WHEN @value = '381b4222-f694-41f0-9685-ff5bb260df2e' then 'Balanced'
WHEN @value = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' then 'High Performance'
ELSE 'Power Saver' 
END as PowerPlan

/*
Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e (Balanced)
Power Scheme GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c (High performance)
Power Scheme GUID: a1841308-3541-4fab-bc81-f71556f20b4a (Power saver)
*/

