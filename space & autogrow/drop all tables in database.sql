--Be sure to run this against the correct database
--Once the output has been generated, verify the table names match the desired database
--then open a new query and execute this output

if (select DB_ID()) > 5
BEGIN
print 'use ' + db_name() + + ';
GO'
exec sp_MSforeachtable
'
declare @table varchar(256)
set @table = ''?''
print ''drop table '' + @table + ''
GO
''
'
END
ELSE 
PRINT 'Please verify the database you are running this against.  Do not run against system databases.'
