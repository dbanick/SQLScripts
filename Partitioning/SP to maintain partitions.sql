USE [AlphaNumericData]
GO
/****** Object:  StoredProcedure [dbo].[ObsQCHourly_Partition_Switch]    Script Date: 1/8/2025 9:09:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- //   2.0   2020-05-21  RDX		Added logic to cleanup partitions on left and right if it fails partway through; added retry logic to rollback and retry if victim of a deadlock
-- //   3.0   2024-08-15  Navisite		Rewrote it as we are no longer switching to a new table for the delete. Streamlined the partition logic so it will create/drop partitions in a WHILE loop to create partitions as needed
ALTER procedure [dbo].[ObsQCHourly_Partition_Switch] AS 
BEGIN

--DECLARE VARIABLES
	DECLARE @RetryCounter INT, @MaxRetry INT, @leftParts INT, @rightParts INT, @days INT
	SET @RetryCounter = 1 --initialize counter
	SET @MaxRetry = 5 -- number of retries
	SET @days = 90 --how many days of data we should have in the table
	SET @leftParts = 10 --how many empty partitions on the left we want to maintain
	SET @rightParts = 15 --how many empty partitions on the right we want to maintain

	--find earliest date of the partitions
	DECLARE @EarliestDate datetime
	SET @EarliestDate = cast((select top 1 [value] from sys.partition_range_values
		   where function_id = (select function_id 
				   from sys.partition_functions
				   where name = 'pfnObsQCHourly')
		  order by boundary_id ASC) as datetime)
	select @EarliestDate

	--find end date of the partitions
	DECLARE @EndDate datetime;
	SET @EndDate = cast((select top 1 [value] from sys.partition_range_values
		   where function_id = (select function_id 
				   from sys.partition_functions
				   where name = 'pfnObsQCHourly')
		  order by boundary_id DESC) as datetime);
	SET @EndDate = DATEADD(DD, 1, @EndDate);
	select @EndDate

	--this is where the left boundary for the partition should be set to
	--this is based on the total number of days we should have plus number of empty partitions
	DECLARE @startRange datetime
	select @startRange = DATEADD(DD, -(@days + @leftParts),cast(getdate() as date))

	--this is where the right boundary for the partition should be set to
	DECLARE @endRange datetime
	select @endRange = DATEADD(DD, @rightParts, cast(getdate() as date))
	select @startRange, @endRange
	   
	--create temp table	   
	create table #tmp_partition (
	partitionNumber int,
	lowerBoundary datetime,
	upperBoundary datetime,
	rowCnt int
	)

	--populate temp table
	insert into #tmp_partition
	SELECT
		p.partition_number AS 'PartitionNumber'
		,cast(prv_left.value as datetime) AS 'LowerBoundary'
		,cast(prv_right.value as datetime) AS 'UpperBoundary'
		,CASE
			WHEN p.index_id IN (0,1) THEN p.row_count
			ELSE 0
		END AS 'RowCount'
		  FROM sys.dm_db_partition_stats p
		INNER JOIN sys.indexes i
			ON i.OBJECT_ID = p.OBJECT_ID AND i.index_id = p.index_id
		LEFT OUTER JOIN sys.partition_schemes ps
			ON ps.data_space_id = i.data_space_id
		LEFT OUTER JOIN sys.partition_range_values prv_right
			ON prv_right.function_id = ps.function_id
			AND prv_right.boundary_id = p.partition_number
		LEFT OUTER JOIN sys.partition_range_values prv_left
			ON prv_left.function_id = ps.function_id
			AND prv_left.boundary_id = p.partition_number - 1
	WHERE
		OBJECTPROPERTY(p.OBJECT_ID, 'ISMSSHipped') = 0
		and OBJECT_NAME(p.OBJECT_ID) = 'ObsQCHourly'
		and p.index_id in (0,1)

	DECLARE @EarliestPopulated datetime, @LatestPopulated datetime
	select @EarliestPopulated = coalesce(lowerboundary, upperboundary) from #tmp_partition where rowCnt >0 order by partitionNumber desc
	select @LatestPopulated = coalesce(upperboundary, lowerboundary) from #tmp_partition where rowCnt >0 order by partitionNumber asc
	select @EarliestPopulated as earliestpopulatedpartition, @LatestPopulated as latestpopulatedpartition

	--SWITCH PARTITIONS
	RETRY: -- Label RETRY
	BEGIN TRANSACTION
	BEGIN TRY

	
		--find number of empty left partitions		
		DECLARE @numEmptyPartitions int;
		select @numEmptyPartitions = count(1) from #tmp_partition where lowerBoundary < @EarliestPopulated and rowCnt = 0
		select @numEmptyPartitions as numberOfEmptyLeftPartitions;	
	
		--remove far left partition if we have enough empty partitions on the left and it is empty
		if (@numEmptyPartitions > @leftParts) and exists (select partitionNumber from #tmp_partition where rowCnt = 0 and partitionNumber = 1 and upperBoundary != @EarliestPopulated)
			begin
				-- MERGE Partition Statement to merge ObsQCHourly table first partition
				ALTER PARTITION FUNCTION [pfnObsQCHourly] ()
				MERGE RANGE (@EarliestDate);

				--update earliest partition variable
				SET @EarliestDate = cast((select top 1 [value] from sys.partition_range_values
				where function_id = (select function_id 
				from sys.partition_functions
				where name = 'pfnObsQCHourly')
				order by boundary_id ASC) as datetime)

				--update count
				;with cte as (select t.*, (row_number() over (order by RowCnt) ) as id from  #tmp_partition t)
				select @numEmptyPartitions = count(*) from cte where partitionNumber = id
			end


		--check if partition 1 is not empty; we need to split it
		if exists (select partitionNumber from #tmp_partition where partitionNumber = 1 and rowCnt > 0) OR (@numEmptyPartitions > @leftParts)
			begin
			
				--if partition 1 is not empty, we need to split it
				ALTER PARTITION SCHEME [psObsQCHourly]
				NEXT USED [partitioning];

				ALTER PARTITION FUNCTION [pfnObsQCHourly] ()
				SPLIT RANGE (DATEADD(DD, -1, @EarliestDate))
			end


		--check if we have too many partitions on the right
		--find number of empty right partitions		
		DECLARE @numEmptyRightPartitions int;
		select @numEmptyRightPartitions = count(1) from #tmp_partition where lowerBoundary > @LatestPopulated and rowCnt = 0
		select @numEmptyRightPartitions as numberOfEmptyRightPartitions;	
	 
		--create far right partition if we don't have enough
		if (@numEmptyRightPartitions < @rightParts)
			begin
				
				select @numEmptyRightPartitions, @rightParts, @LatestPopulated, @EndDate
				
				-- SPLITING Partition Statement to split ObsQCHourly last partition
				ALTER PARTITION SCHEME [psObsQCHourly]   
				NEXT USED [partitioning]; 

				ALTER PARTITION FUNCTION [pfnObsQCHourly] ()
				SPLIT RANGE (@EndDate);
				
				--update earliest partition variable
				SET @EndDate = cast((select top 1 [value] from sys.partition_range_values
				where function_id = (select function_id 
				from sys.partition_functions
				where name = 'pfnObsQCHourly')
				order by boundary_id DESC) as datetime);
				SET @EndDate = DATEADD(DD, 1, @EndDate);

				--update count
				select @numEmptyRightPartitions = count(1) from #tmp_partition where lowerBoundary > @LatestPopulated and rowCnt = 0
			end

		--if we have too many partitions, then merge the far right one
		if (@numEmptyRightPartitions > @rightParts) AND (select partitionNumber from #tmp_partition where lowerBoundary > @endRange and rowCnt = 0)  > 1
			begin

				--update earliest partition variable
				SET @EndDate = cast((select top 1 [value] from sys.partition_range_values
				where function_id = (select function_id 
				from sys.partition_functions
				where name = 'pfnObsQCHourly')
				order by boundary_id DESC) as datetime);

				select @numEmptyRightPartitions, @rightParts, @LatestPopulated, @EndDate, @endRange
				
				ALTER PARTITION FUNCTION [pfnObsQCHourly] ()
				MERGE RANGE (@EndDate); --@CurrEndDate
			end
			



	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'Rollback Transaction'
		ROLLBACK TRANSACTION
		DECLARE @DoRetry bit; -- Whether to Retry transaction or not
		DECLARE @ErrorMessage varchar(500)
		SET @doRetry = 0;
		SET @ErrorMessage = ERROR_MESSAGE()
		IF ERROR_NUMBER() = 1205 -- Deadlock Error Number
		BEGIN
			SET @doRetry = 1; -- Set @doRetry to 1 only for Deadlock
		END
		IF @DoRetry = 1
		BEGIN
			SET @RetryCounter = @RetryCounter + 1 -- Increment Retry Counter By one
			IF (@RetryCounter > @maxRetry) -- Check whether Retry Counter reached to max
			BEGIN
				RAISERROR(@ErrorMessage, 18, 1) -- Raise Error Message if 
					-- still deadlock occurred after X retries
			END
			ELSE
			BEGIN
				WAITFOR DELAY '00:10:00'  -- Wait for 10 mins
				GOTO RETRY	-- Go to Label RETRY
			END
		END
		ELSE
		BEGIN
			RAISERROR(@ErrorMessage, 18, 1)
		END
	END CATCH

	--re-validate data
	truncate table #tmp_partition
	insert into #tmp_partition
	SELECT
		p.partition_number AS 'PartitionNumber'
		,cast(prv_left.value as datetime) AS 'LowerBoundary'
		,cast(prv_right.value as datetime) AS 'UpperBoundary'
		,CASE
			WHEN p.index_id IN (0,1) THEN p.row_count
			ELSE 0
		END AS 'RowCount'

		  FROM sys.dm_db_partition_stats p
		INNER JOIN sys.indexes i
			ON i.OBJECT_ID = p.OBJECT_ID AND i.index_id = p.index_id
		LEFT OUTER JOIN sys.partition_schemes ps
			ON ps.data_space_id = i.data_space_id
		LEFT OUTER JOIN sys.partition_range_values prv_right
			ON prv_right.function_id = ps.function_id
			AND prv_right.boundary_id = p.partition_number
		LEFT OUTER JOIN sys.partition_range_values prv_left
			ON prv_left.function_id = ps.function_id
			AND prv_left.boundary_id = p.partition_number - 1
	WHERE
		OBJECTPROPERTY(p.OBJECT_ID, 'ISMSSHipped') = 0
		and OBJECT_NAME(p.OBJECT_ID) = 'ObsQCHourly'
		and p.index_id in (0,1)

	
		--select * from #tmp_partition order by 1
	if (@numEmptyPartitions > @leftParts) and exists (select partitionNumber from #tmp_partition where rowCnt = 0 and partitionNumber = 1 and upperBoundary != @EarliestPopulated)
		begin	
			RAISERROR('ObsQCHourly has too many left partitions; run the job again to cleanup more', 18, 1)
		end			
	if exists (select partitionNumber from #tmp_partition where partitionNumber = 1 and rowCnt > 0) 
		begin 
			RAISERROR('ObsQCHourly is missing left partitions; run the job again to add more', 18, 1)
		end
	if (@numEmptyRightPartitions > @rightParts) AND ((select partitionNumber from #tmp_partition where lowerBoundary > @endRange and rowCnt = 0)  > 1)
		begin
			RAISERROR('ObsQCHourly has more partitions than needed; run the job again to cleanup more partitions', 18, 1)
		end
	if ((select count(1) from #tmp_partition where lowerBoundary > @LatestPopulated) < @rightParts)
		begin
			RAISERROR('ObsQCHourly needs more right partitions; run the job again to add more', 18, 1)
		end

	drop table #tmp_partition



end


