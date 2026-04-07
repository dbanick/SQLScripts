DECLARE @currentdate datetime
DECLARE @olddate datetime
DECLARE @daystodelete int
DECLARE @dir varchar(4000)
DECLARE @ext varchar(5)
DECLARE @sub int

set @dir = 'H:\trace' -- Set this to the directory path
set @ext = 'bak' -- Extension of the files you are deleting
set @daystodelete = 4 -- Delete files older than #
set @sub = 1 -- Set to 1 to include first-level subfolders, 0 for only the current directory


set @currentdate = CURRENT_TIMESTAMP
set @olddate = @currentdate - @daystodelete

EXECUTE master.dbo.xp_delete_file 0,@dir,@ext,@olddate,@sub
			
--select @olddate , @currentdate
