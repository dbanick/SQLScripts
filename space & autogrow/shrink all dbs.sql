DECLARE @ScriptToExecute VARCHAR(MAX);
DECLARE @NewLine AS CHAR(2) = CHAR(13) + CHAR(10)

SET @ScriptToExecute = '';
SELECT
@ScriptToExecute = @ScriptToExecute +
'USE ['+ d.name +'];' + @NewLine + 'DBCC SHRINKFILE (N''' + f.name + N''' ,1024)' + @NewLine
FROM sys.master_files f
INNER JOIN sys.databases d ON d.database_id = f.database_id
WHERE d.database_id > 4 and f.type_desc = 'LOG' and d.state_desc = 'ONLINE' and f.size > 131072
SELECT @ScriptToExecute ScriptToExecute
EXEC (@ScriptToExecute)
