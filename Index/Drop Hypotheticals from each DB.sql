--check for hypothetical indexes in each database. This will generate commands to drop them but doesn't execute the drop


SET QUOTED_IDENTIFIER OFF
use msdb
exec sp_MSforeachdb
"
use [?]
 IF '[?]' NOT IN ('tempdb')

select top 1 'USE [?]' from sys.indexes where is_hypothetical = 1
UNION ALL
SELECT
   'DROP INDEX [' + i.name + '] ON [dbo].[' + t.name + ']' --+ CHAR(13) + CHAR(10)
FROM 
    sys.indexes i 
    INNER JOIN sys.tables t 
        ON i.object_id = t.object_id 
WHERE 
    i.is_hypothetical = 1

"
SET QUOTED_IDENTIFIER ON