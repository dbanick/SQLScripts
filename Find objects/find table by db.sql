use msdb
exec sp_msforeachdb '
use ?
select ''?'' as [dbName], name from sys.objects where name like ''%F90703%'' or name like ''%F90704%''
'