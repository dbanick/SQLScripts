--change the below variable as needed; 
-- example: if you want files to have 30% free space, set the desired % free variable to 70
declare @desiredPCTFree int
set @desiredPCTFree = 70

--change @execute to 1 if you want it to actually run the commands
declare @execute bit
set @execute = 0


--declare variables
declare @newSize int
declare @sizeToGrow int
declare @growthIncrement int
declare @currentSize int
declare @growthTimes int
declare @counter int
declare @dbName varchar(256) 
declare @fileName varchar(256) 
declare @cmd varchar(4000)

--create table to hold errors
create table #rdxcmd (
	id int identity, 
	cmd varchar(4000),
	error bit default 0
)

--create table for xp_fixeddrives
create table #tempDrives(
	"Drive" varchar(3),
	"MB_Free" int
)

--create table for current size information
CREATE TABLE #rdxoutput
    (
      [Server Name] varchar(128),
      [Database Name] varchar(128),
      [File Name] VARCHAR(128),
      [File ID] INT,
      [Physical File Name] varchar(260),
      [Total Size in MB] FLOAT,
      [Available Space in MB] FLOAT,
	  [Free%] INT
    );  

--populate the drives table
insert into #tempDrives
exec xp_fixeddrives

--populate the drive space table
INSERT INTO #rdxoutput
exec sp_MSforeachdb @command1 = 'USE [?]; 
SELECT CAST(SERVERPROPERTY(''ServerName'') AS varchar(128)) AS [Server Name], 
''?'' AS [Database Name], 
f.name as [File Name],
f.file_id as [File ID],
f.physical_name AS [Physical File Name],  
size/128.0 AS ''[Total Size in MB]'', 
size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int)/128.0 AS ''[Available Space in MB]'',
100-(((FILEPROPERTY (Name, ''SpaceUsed'')/128)*100/NULLIF(((CONVERT(BIGINT,Size) * 8 /1024)),0))) AS [Free%]
FROM sys.database_files f'


--build cursor to loop through each file
--use CEILING function to round up to whole sizes
declare fileCursor CURSOR for 	SELECT rdx.[Database Name], rdx.[File Name],
	CEILING((rdx.[Total Size in MB] - rdx.[Available Space in MB]) * 100 / @desiredPCTFree) as newSize,
	CEILING(rdx.[Total Size in MB]) as  currentSize,
	CEILING(((rdx.[Total Size in MB] - rdx.[Available Space in MB]) * 100 / @desiredPCTFree) - rdx.[Total Size in MB]) as sizeToGrow,
	CEILING((((rdx.[Total Size in MB] - rdx.[Available Space in MB]) * 100 / @desiredPCTFree) - rdx.[Total Size in MB])/3) as growthIncrement
	FROM #rdxoutput as rdx
	WHERE [Free%] < 100-@desiredPCTFree 
	ORDER BY [Database Name]

Open fileCursor

Fetch next from fileCursor
into @dbName, @fileName, @newSize, @currentSize, @sizeToGrow, @growthIncrement

--while there are files to process
WHILE @@FETCH_STATUS = 0
	BEGIN 
		--check if there is enough space to grow the file; if not, throw an error in the output table
		IF ((SELECT drive.MB_Free FROM #rdxoutput as rdx join #tempDrives as drive on drive.Drive = LEFT(rdx.[Physical File Name],1) where [Database Name] = @dbName and rdx.[File Name] = @fileName ) < @sizeToGrow)
			BEGIN
				insert into #rdxcmd select 'not enough space to grow to 30% free space for ' + @dbName + '; this grow command is skipped', 1
			END
		ELSE --if there is sufficient space to grow, perform an autogrow based on the below logic
			BEGIN
				--if file only needs 500MB more space, then grow in one chunk
				IF @sizeToGrow < 500
					BEGIN
						insert into #rdxcmd select 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast(@newSize as varchar(250)) + ' )', 0
						insert into #rdxcmd select 'GO', 0
						--execute the commands if flag is set
						if @execute = 1
							begin
								set @cmd = 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast(@newSize as varchar(250)) + ' )'
								execute(@cmd)
							end
					END
				-- if total file growth is under 8GB but over 500MB, grow in three chunks
				IF @sizeToGrow >= 500 and @sizeToGrow  < 8000
					BEGIN
						insert into #rdxcmd select 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast((@currentSize + @growthIncrement) as varchar(250)) + ' )' , 0
						insert into #rdxcmd select 'GO', 0
						insert into #rdxcmd select 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast((@currentSize + @growthIncrement + @growthIncrement) as varchar(250)) + ' )', 0
						insert into #rdxcmd select 'GO', 0
						insert into #rdxcmd select 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast(@newSize as varchar(250)) + ' )', 0
						insert into #rdxcmd select 'GO', 0
						--execute the commands if flag is set
						if @execute = 1
							begin
								set @cmd = 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast((@currentSize + @growthIncrement) as varchar(250)) + ' )' 
								execute(@cmd)
								set @cmd = 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast((@currentSize + @growthIncrement + @growthIncrement) as varchar(250)) + ' )'
								execute(@cmd)
								set @cmd = 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast(@newSize as varchar(250)) + ' )'
								execute(@cmd)
							end
					END
				--if the file needs to grow more than 8GB, then we will grow in 8GB chunks
				IF @sizeToGrow >= 8000
					BEGIN
						--find out how many full growths of 8GB we need; set growth increment to 8GB
						SET @growthTimes = FLOOR((SELECT (@newSize - @currentSize)/8000))
						SET @growthIncrement  = 8000

						--while we need to do a full growth, generate the alter command, and adjust the current size variable
						WHILE @counter <= @growthTimes
							BEGIN
								insert into #rdxcmd select 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast((@currentSize + @growthIncrement) as varchar(250)) + ' )', 0
								insert into #rdxcmd select 'GO', 0
								set @currentSize = @currentSize + @growthIncrement
								--execute the commands if flag is set
								if @execute = 1
									begin
										set @cmd = 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast((@currentSize + @growthIncrement) as varchar(250)) + ' )'
										execute(@cmd)
									end
							END
					
						--after all the full 8GB growths are scripted, generate the final script to set it to the desired new size
						insert into #rdxcmd select 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast(@newSize as varchar(250)) + ' )', 0
						insert into #rdxcmd select 'GO', 0
						--execute the commands if flag is set
						if @execute = 1
							begin
								set @cmd = 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @fileName + ''', SIZE = ' + cast(@newSize as varchar(250)) + ' )'
								execute @cmd
							end
					END
			END

		--reload the drive info table so we can compare the next growth to the updated drive space
		truncate table #tempDrives

		insert into #tempDrives
		exec xp_fixeddrives
		
		--fetch next for cursor
		Fetch next from fileCursor
		into @dbName, @fileName, @newSize, @currentSize, @sizeToGrow, @growthIncrement
	END
CLOSE fileCursor
DEALLOCATE fileCursor

--if there were errors, output that first
IF (select count(1) from #rdxcmd  where error = 1) > 0
	SELECT cmd from #rdxcmd  where error = 1 order by id asc

--if there are no files to grow, notify that
IF (select count(1) from #rdxcmd) =0
	select 'There are no files to grow on this server; all files have at least ' + cast((100- @desiredPCTFree) as varchar(250)) + '% free space'

--pull the commands from the table
IF (select count(1) from #rdxcmd  where error = 0) > 0
	select cmd from #rdxcmd where error = 0 order by id asc

go
--cleanup temp tables
DROP TABLE #rdxoutput; 
DROP TABLE #tempDrives; 
DROP TABLE #rdxcmd;

