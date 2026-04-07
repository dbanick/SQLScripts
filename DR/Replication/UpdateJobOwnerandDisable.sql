USE MSDB;
GO
UPDATE J
SET J.Enabled = 0, owner_sid  = suser_sid('sa')
FROM MSDB.dbo.sysjobs J
INNER JOIN MSDB.dbo.syscategories C
ON J.category_id = C.category_id
WHERE C.[Name] like  '%Repl%';
GO