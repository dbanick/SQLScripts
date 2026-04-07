   -- Determine the logical file names for the tempdb database.

USE tempdb
GO
EXEC sp_helpfile
GO
--The logical name for each file is contained in the NAME column.

    --Change the location of each file using ALTER DATABASE.

USE master
GO
ALTER DATABASE tempdb 
MODIFY FILE (NAME = tempdev, FILENAME = 'I:\MSSQL\DATA\tempdb.mdf')
GO
ALTER DATABASE  tempdb 
MODIFY FILE (NAME = templog, FILENAME = 'I:\MSSQL\DATA\templog.ldf')
GO

   -- Stop and restart SQL Server.
