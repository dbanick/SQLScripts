--see current size in KB
use tempdb
select (size*8) as FileSizeKB from sys.database_files

--database files

use master
go
select * from sys.master_files
go


Select name, physical_name, (size * 8 ) / 1024.0 as mbs from sys.master_files
