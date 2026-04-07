use msdb
exec sp_msforeachdb
'
use [?]
select ''?'' as [db], object_name(id), text from    
syscomments where text like ''%MaterialPerLocation%'' 
'