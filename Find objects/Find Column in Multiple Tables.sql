If OBJECT_ID('TempDB..#TempDItable', 'U') > 0
Drop Table #TempDItable
Create Table #TempDItable (ServerName VarChar(255),DBName VarChar(125), tablename VarChar(500), columnname VarChar(300))
Insert Into #TempDItable
exec sp_MSforeachdb
'
use[?]
SELECT @@servername as Servername, ''?'' AS Database_Name,
t.name AS table_name,
c.name AS column_name
FROM sysobjects AS t
INNER JOIN syscolumns c ON t.id = c.id
and t.xtype = ''u''
WHERE c.name LIKE ''%SSN%'' 
ORDER BY table_name;
'
Select * From #TempDItable
--Drop Table #TempDItable