USE [DBA] /* Set Database */
GO
DECLARE @sizeint INT
	,@size VARCHAR(8)
	,@cmd NVARCHAR(2048)
	,@database VARCHAR(255) = 'DBA' /* Set Database */
	,@logicalfile VARCHAR(255) = 'DBA_data' /* Set Datafile */
	,@shrinkinterval int = 256 /* Set shrink interval */
	,@targetsize int = 8192 /* Set desired final size */

SET @sizeint = (
		SELECT size / 128
		FROM sys.master_files
		WHERE DB_NAME(database_id) = @database
			AND name = @logicalfile
		)

WHILE @sizeint > @targetsize 
BEGIN
	SET @sizeint = @sizeint - @shrinkinterval 
	SET @size = convert(VARCHAR(8), @sizeint)
	SET @cmd = N'DBCC SHRINKFILE (name = ''' + @logicalfile + ''', ' + @size + ');'

	EXEC sp_executesql @cmd

END


