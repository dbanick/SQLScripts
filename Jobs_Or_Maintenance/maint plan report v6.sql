--Provides a summary of all native maintenance plans

USE master
GO

DECLARE @debug bit
SET @debug = 0
SET NOCOUNT ON

-- Create Tables
CREATE TABLE #MaintPlansReport (
	MaintPlanName VARCHAR(2770)
	,SubPlanName VARCHAR(2770)
	,InstanceName VARCHAR(100)
	,
	--[UserID] varchar(200) NULL,	 
	TaskName VARCHAR(2770)
	,TaskType VARCHAR(2000)
	,TaskEnabled CHAR(3)
	,DatabaseSelectionType VARCHAR(4000)
	,IgnoreOfflineDatabases CHAR(3)
	,TaskOptions VARCHAR(2000)
	)

CREATE TABLE #MaintPlanConnections1 (
	[id] [int] IDENTITY(1, 1) NOT NULL
	,[PlanText] [varchar](max) NULL
	)

CREATE TABLE #MaintPlanConnections2 (
	[id] [int] IDENTITY(0, 1) NOT NULL
	,[ConnectionID] VARCHAR(1000) NULL
	,[ConnectionName] [varchar](1000) NULL
	,[InstanceName] [varchar](1000) NULL
	,[ConnectionUserID] [varchar](2000) NULL
	)

CREATE TABLE [dbo].[#MaintPlans] (
	[id] [int] IDENTITY(1, 1) NOT NULL
	,[MaintPlanName] [varchar](2770) NULL
	,[packagedata] [image] NULL
	)

CREATE TABLE [dbo].[#MaintTask1] (
	[id] [int] IDENTITY(1, 1) NOT NULL
	,[SubPlanID] [int] NOT NULL
	,[PlanText] [varchar](max) NULL
	,[TaskName] [varchar](1000) NULL
	,[TaskType] [varchar](8000) NULL
	,[Server] VARCHAR(100) NULL
	,[TaskEnabled] [char](3) DEFAULT('Yes') NULL
	,[DatabaseSelectionType] [varchar](8000) NULL
	,[IgnoreDatabaseState] [char](3) DEFAULT('No') NULL
	,[TaskOptions] [varchar](8000) DEFAULT('') NULL
	)

CREATE TABLE [dbo].[#SUBPLANS1] (
	[id] [int] IDENTITY(1, 1) NOT NULL
	,[PlanText] [varchar](max) NULL
	)

CREATE TABLE [dbo].[#SUBPLANS2] (
	[id] [int] IDENTITY(1, 1) NOT NULL
	,[SubPlanName] [varchar](2770) NULL
	,[PlanText] [varchar](max) NULL
	)

DECLARE @version INT
	,@exec VARCHAR(200)

SET @version = (
		SELECT cast(substring(CAST(serverproperty('ProductVersion') AS VARCHAR(50)), 1, patindex('%.%', CAST(serverproperty('ProductVersion') AS VARCHAR(50))) - 1) AS INT)
		)

IF @version = 9
BEGIN
	SET @exec = 'insert into #MaintPlans (MaintPlanName, packagedata) Select name, packagedata from msdb..sysdtspackages90 where packagetype = 6'

	EXEC (@exec)
END
ELSE IF @version > 9
BEGIN
	SET @exec = 'insert into #MaintPlans (MaintPlanName, packagedata) Select name, packagedata from msdb..sysssispackages where packagetype = 6'

	EXEC (@exec)
END

DECLARE @MaintID INT
	,@MaintPlanName VARCHAR(277)

SET @MaintID = 1

WHILE @MaintID <= (
		SELECT MAX(id)
		FROM #MaintPlans
		)
BEGIN
	-- Table Cleanup
	TRUNCATE TABLE #SUBPLANS1

	TRUNCATE TABLE #SUBPLANS2

	TRUNCATE TABLE #MaintTask1

	TRUNCATE TABLE #MaintPlanConnections1

	TRUNCATE TABLE #MaintPlanConnections2

	-- Grab Connection Info Part 1
	DECLARE @ConnectPlan1 VARCHAR(max)
		,@ConnectPlan1String VARCHAR(max)
	
	
	SELECT @ConnectPlan1 = cast(cast([packagedata] AS VARBINARY(max)) AS VARCHAR(max))
		,@MaintPlanName = MaintPlanName
	FROM #MaintPlans
	WHERE id = @MaintID
	
	IF @debug = 1
	begin
	SELECT '@ConnectPlan1',@MaintPlanName, @ConnectPlan1
	end

	IF @ConnectPlan1 IS NOT NULL
	BEGIN
		IF CHARINDEX('<DTS:ConnectionManager>' + CHAR(13) + CHAR(10) + '<DTS:Property DTS:Name="DelayValidation">0</DTS:Property>', @ConnectPlan1) <> 0 -- For multiple databases in the parameter
		BEGIN
			SET @ConnectPlan1String = @ConnectPlan1;

			WHILE CHARINDEX('<DTS:ConnectionManager>' + CHAR(13) + CHAR(10) + '<DTS:Property DTS:Name="DelayValidation">0</DTS:Property>', @ConnectPlan1String) <> 0
			BEGIN
				INSERT INTO #MaintPlanConnections1 (PlanText)
				VALUES (Left(@ConnectPlan1String, CHARINDEX('<DTS:ConnectionManager>' + CHAR(13) + CHAR(10) + '<DTS:Property DTS:Name="DelayValidation">0</DTS:Property>', @ConnectPlan1String) - 1));

				SET @ConnectPlan1String = Right(@ConnectPlan1String, Len(@ConnectPlan1String) - CHARINDEX('<DTS:ConnectionManager>' + CHAR(13) + CHAR(10) + '<DTS:Property DTS:Name="DelayValidation">0</DTS:Property>', @ConnectPlan1String));
			END

			INSERT INTO #MaintPlanConnections1 (PlanText)
			VALUES (@ConnectPlan1String);
		END
	END

	--2012+
	IF @ConnectPlan1 like '%<DTS:ConnectionManager DTS:refId%'-- For multiple databases in the parameter
	BEGIN
		SET @ConnectPlan1String = @ConnectPlan1;


			WHILE CHARINDEX('<DTS:ConnectionManager DTS:refId', @ConnectPlan1String) <> 0
			BEGIN
				INSERT INTO #MaintPlanConnections1 (PlanText)
				VALUES (Left(@ConnectPlan1String, CHARINDEX('<DTS:ConnectionManager DTS:refId', @ConnectPlan1String) ));

				SET @ConnectPlan1String = Right(@ConnectPlan1String, Len(@ConnectPlan1String) - CHARINDEX('<DTS:ConnectionManager DTS:refId', @ConnectPlan1String));
			END

		INSERT INTO #MaintPlanConnections1 (PlanText)
		VALUES (@ConnectPlan1String);
	END
	--2012 alternate version
	IF @ConnectPlan1 like '%<DTS:ConnectionManager DTS:ObjectName=%'
			BEGIN

					SET @ConnectPlan1String = @ConnectPlan1;

				WHILE CHARINDEX('<DTS:ConnectionManager DTS:ObjectName=', @ConnectPlan1String) <> 0
				BEGIN
				INSERT INTO #MaintPlanConnections1 (PlanText)
				VALUES (Left(@ConnectPlan1String, CHARINDEX('<DTS:ConnectionManager DTS:ObjectName=', @ConnectPlan1String) ));

				SET @ConnectPlan1String = Right(@ConnectPlan1String, Len(@ConnectPlan1String) - CHARINDEX('<DTS:ConnectionManager DTS:ObjectName=', @ConnectPlan1String));
				END

		INSERT INTO #MaintPlanConnections1 (PlanText)
		VALUES (@ConnectPlan1String);
	END

	IF @debug = 1
	begin
	select 'select from #MaintPlanConnections1', * from #MaintPlanConnections1
	end

	DELETE
	FROM #MaintPlanConnections1
	WHERE id = 1

	IF @debug = 1
	begin
	select 'select from #MaintPlanConnections1', * from #MaintPlanConnections1
	end
	IF (
			SELECT count(*)
			FROM #MaintPlanConnections1
			) = 0
		AND @version <= 9 -- 2005 Connection Strings
	BEGIN
		--Declare @ConnectPlan1 varchar(max), @ConnectPlan1String varchar(max)
		SELECT @ConnectPlan1 = cast(cast([packagedata] AS VARBINARY(max)) AS VARCHAR(max))
			,@MaintPlanName = MaintPlanName
		FROM #MaintPlans
		WHERE id = @MaintID

		IF @ConnectPlan1 IS NOT NULL
		BEGIN
			IF CHARINDEX('<DTS:ConnectionManager><DTS:Property DTS:Name="DelayValidation">0</DTS:Property>', @ConnectPlan1) <> 0 -- For multiple databases in the parameter
			BEGIN
				SET @ConnectPlan1String = @ConnectPlan1;

				WHILE CHARINDEX('<DTS:ConnectionManager><DTS:Property DTS:Name="DelayValidation">0</DTS:Property>', @ConnectPlan1String) <> 0
				BEGIN
					INSERT INTO #MaintPlanConnections1 (PlanText)
					VALUES (Left(@ConnectPlan1String, CHARINDEX('<DTS:ConnectionManager><DTS:Property DTS:Name="DelayValidation">0</DTS:Property>', @ConnectPlan1String) - 1));

					SET @ConnectPlan1String = Right(@ConnectPlan1String, Len(@ConnectPlan1String) - CHARINDEX('<DTS:ConnectionManager><DTS:Property DTS:Name="DelayValidation">0</DTS:Property>', @ConnectPlan1String));
				END

				INSERT INTO #MaintPlanConnections1 (PlanText)
				VALUES (@ConnectPlan1String);
			END
		END

		DELETE
		FROM #MaintPlanConnections1
		WHERE id = 1
	END

	IF @debug = 1
	begin
	select 'maintplancons1', * from #MaintPlanConnections1 
	end

	-- Grab Connection Info Part 2
	DECLARE @ConnectPlan2 VARCHAR(max)
		,@MaintConnectID INT
		,@ConnectionName VARCHAR(200)
		,@ConnectionServer VARCHAR(200)
		,@ConnectionID VARCHAR(100)
		,@ConnectionUserID VARCHAR(200)

	SELECT @MaintConnectID = MIN(id)
	FROM #MaintPlanConnections1

	IF @version <= 10
		WHILE @MaintConnectID <= (
				SELECT MAX(id)
				FROM #MaintPlanConnections1
				)
		BEGIN
			SELECT @ConnectPlan2 = [PlanText]
			FROM #MaintPlanConnections1
			WHERE id = @MaintConnectID

			-- ConnectionID
			SELECT @ConnectionID = SUBSTRING(@ConnectPlan2, CHARINDEX('<DTS:Property DTS:Name="DTSID">{', @ConnectPlan2) + LEN('<DTS:Property DTS:Name="DTSID">{'), CHARINDEX('}</DTS:Property>', @ConnectPlan2, CHARINDEX('<DTS:Property DTS:Name="DTSID">{', @ConnectPlan2)) - (CHARINDEX('<DTS:Property DTS:Name="DTSID">{', @ConnectPlan2) + LEN('<DTS:Property DTS:Name="DTSID">{')))

			-- ConnectionName
			SELECT @ConnectionName = SUBSTRING(@ConnectPlan2, CHARINDEX('<DTS:Property DTS:Name="ObjectName">', @ConnectPlan2) + LEN('<DTS:Property DTS:Name="ObjectName">'), CHARINDEX('</DTS:Property>', @ConnectPlan2, CHARINDEX('<DTS:Property DTS:Name="ObjectName">', @ConnectPlan2)) - (CHARINDEX('<DTS:Property DTS:Name="ObjectName">', @ConnectPlan2) + LEN('<DTS:Property DTS:Name="ObjectName">')))

			SELECT @ConnectionName = SUBSTRING(@ConnectionName, CHARINDEX('=', @ConnectionName) + 1, LEN(@ConnectionName))

			-- Server
			SELECT @ConnectionServer = SUBSTRING(@ConnectPlan2, CHARINDEX('<DTS:Property DTS:Name="ConnectionString">', @ConnectPlan2) + LEN('<DTS:Property DTS:Name="ConnectionString">'), CHARINDEX(';', @ConnectPlan2, CHARINDEX('<DTS:Property DTS:Name="ConnectionString">', @ConnectPlan2)) - (CHARINDEX('<DTS:Property DTS:Name="ConnectionString">', @ConnectPlan2) + LEN('<DTS:Property DTS:Name="ConnectionString">')))

			SELECT @ConnectionServer = Replace(SUBSTRING(@ConnectionServer, CHARINDEX('=', @ConnectionServer) + 1, LEN(@ConnectionServer)), '''', '')

			--				IF CHARINDEX('uid=', @ConnectPlan2) > 0
			--					BEGIN
			--						Select @ConnectionUserID=Replace(SUBSTRING(@ConnectPlan2, CHARINDEX('uid=',@ConnectPlan2)+4, LEN(@ConnectPlan2)),'''','')
			--						Select @ConnectionUserID=SUBSTRING(@ConnectionUserID, 1,CHARINDEX(';',@ConnectionUserID)-1)
			--					END
			--				  ELSE 
			--					SET @ConnectionUserID = 'Trusted_Connection=true'
			
			
			
			INSERT INTO #MaintPlanConnections2 (
				[ConnectionID]
				,[ConnectionName]
				,[InstanceName]
				)
			VALUES (
				@ConnectionID
				,@ConnectionName
				,@ConnectionServer
				)

			SET @MaintConnectID = @MaintConnectID + 1
		END

	IF @version >= 11
		WHILE @MaintConnectID <= (
				SELECT MAX(id)
				FROM #MaintPlanConnections1
				)
		BEGIN
			SELECT @ConnectPlan2 = [PlanText]
			FROM #MaintPlanConnections1
			WHERE id = @MaintConnectID

			--
			-- ConnectionID
			SELECT @ConnectionID = SUBSTRING(@ConnectPlan2, CHARINDEX('DTS:DTSID="', @ConnectPlan2) + LEN('DTS:DTSID="') + 1, CHARINDEX('}"', @ConnectPlan2, CHARINDEX('DTS:DTSID="', @ConnectPlan2)) - (CHARINDEX('DTS:DTSID="', @ConnectPlan2) + LEN('DTS:DTSID="') + 1))

			-- ConnectionName
			SELECT @ConnectionName = SUBSTRING(@ConnectPlan2, CHARINDEX('}" DTS:ObjectName="', @ConnectPlan2) + LEN('}" DTS:ObjectName="'), CHARINDEX('">', @ConnectPlan2, CHARINDEX('}" DTS:ObjectName="', @ConnectPlan2)) - (CHARINDEX('}" DTS:ObjectName="', @ConnectPlan2) + LEN('}" DTS:ObjectName="')))
			if @ConnectionName like '%" DTS:DTSID="{%'
			SELECT @ConnectionName = SUBSTRING(@ConnectPlan2, CHARINDEX('}" DTS:ObjectName="', @ConnectPlan2) + LEN('}" DTS:ObjectName="'), CHARINDEX('" DTS:DTSID="{', @ConnectPlan2, CHARINDEX('}" DTS:ObjectName="', @ConnectPlan2)) - (CHARINDEX('}" DTS:ObjectName="', @ConnectPlan2) + LEN('}" DTS:ObjectName="')))

			SELECT @ConnectionName = REPLACE(SUBSTRING(@ConnectionName, CHARINDEX('=', @ConnectionName) + 1, LEN(@ConnectionName)), '"', '')

			-- Server
			SELECT @ConnectionServer = SUBSTRING(@ConnectPlan2, CHARINDEX('<DTS:ConnectionManager DTS:ConnectionString="Data Source=', @ConnectPlan2) + LEN('<DTS:ConnectionManager DTS:ConnectionString="Data Source='), CHARINDEX(';', @ConnectPlan2, CHARINDEX('<DTS:ConnectionManager DTS:ConnectionString="Data Source=', @ConnectPlan2)) - (CHARINDEX('<DTS:ConnectionManager DTS:ConnectionString="Data Source=', @ConnectPlan2) + LEN('<DTS:ConnectionManager DTS:ConnectionString="Data Source=')))
			
			SELECT @ConnectionServer = Replace(SUBSTRING(@ConnectionServer, CHARINDEX('=', @ConnectionServer) + 1, LEN(@ConnectionServer)), '''', '')

			--				IF CHARINDEX('uid=', @ConnectPlan2) > 0
			--					BEGIN
			--						Select @ConnectionUserID=Replace(SUBSTRING(@ConnectPlan2, CHARINDEX('uid=',@ConnectPlan2)+4, LEN(@ConnectPlan2)),'''','')
			--						Select @ConnectionUserID=SUBSTRING(@ConnectionUserID, 1,CHARINDEX(';',@ConnectionUserID)-1)
			--					END
			--				  ELSE 
			--					SET @ConnectionUserID = 'Trusted_Connection=true'
			if @debug=1
			begin
				select 'INSERT INTO #MaintPlanConnections2'
				,@MaintPlanName
				,@ConnectionID
				,@ConnectionName
				,@ConnectionServer
			end
			
			INSERT INTO #MaintPlanConnections2 (
				[ConnectionID]
				,[ConnectionName]
				,[InstanceName]
				)
			VALUES (
				@ConnectionID
				,@ConnectionName
				,@ConnectionServer
				)

			IF @debug = 1
			begin
				select '#maintplanconnections2',*
				FROM #MaintPlanConnections2
			end

			SET @MaintConnectID = @MaintConnectID + 1
		END
---------------------------
	-- Part 1 Delimit
	DECLARE @SubPlan1 VARCHAR(max)
		,@SubPlanString1 VARCHAR(max)

	SELECT @SubPlan1 = cast(cast([packagedata] AS VARBINARY(max)) AS VARCHAR(max))
		,@MaintPlanName = MaintPlanName
	FROM #MaintPlans
	WHERE id = @MaintID

	--select 'delimit'
	IF @version <= 10
	BEGIN
		IF @SubPlan1 IS NOT NULL
		BEGIN
			IF CHARINDEX('<DTS:Property DTS:Name="CreationName">STOCK:SEQUENCE</DTS:Property>', @SubPlan1) <> 0 -- For multiple databases in the parameter
			BEGIN
				SET @SubPlanString1 = @SubPlan1;

				WHILE CHARINDEX('<DTS:Property DTS:Name="CreationName">STOCK:SEQUENCE</DTS:Property>', @SubPlanString1) <> 0
				BEGIN
					INSERT INTO #SUBPLANS1 (PlanText)
					VALUES (Left(@SubPlanString1, CHARINDEX('<DTS:Property DTS:Name="CreationName">STOCK:SEQUENCE</DTS:Property>', @SubPlanString1) - 1));

					SET @SubPlanString1 = Right(@SubPlanString1, Len(@SubPlanString1) - CHARINDEX('<DTS:Property DTS:Name="CreationName">STOCK:SEQUENCE</DTS:Property>', @SubPlanString1));
				END

				INSERT INTO #SUBPLANS1 (PlanText)
				VALUES (@SubPlanString1);
			END
		END

		DELETE
		FROM #SUBPLANS1
		WHERE id = (
				SELECT MAX(id)
				FROM #SUBPLANS1
				)
	END

	IF @version >= 11
	BEGIN

		IF @SubPlan1 IS NOT NULL
		BEGIN
		IF CHARINDEX('DTS:CreationName="STOCK:SEQUENCE"', @SubPlan1) <> 0 -- For multiple databases in the parameter
			BEGIN
				SET @SubPlanString1 = @SubPlan1;

				WHILE CHARINDEX('DTS:CreationName="STOCK:SEQUENCE"', @SubPlanString1) <> 0
				BEGIN
					INSERT INTO #SUBPLANS1 (PlanText)
					VALUES (Left(@SubPlanString1, CHARINDEX('DTS:CreationName="STOCK:SEQUENCE"', @SubPlanString1) - 1));

					SET @SubPlanString1 = Right(@SubPlanString1, Len(@SubPlanString1) - CHARINDEX('DTS:CreationName="STOCK:SEQUENCE"', @SubPlanString1));
				END

				--select @SubPlanString1
				INSERT INTO #SUBPLANS1 (PlanText)
				VALUES ('D' + @SubPlanString1);
			END
		
				IF CHARINDEX('DTS:ExecutableType="STOCK:SEQUENCE"', @SubPlan1) <> 0 -- For multiple databases in the parameter
			BEGIN
				SET @SubPlanString1 = @SubPlan1;

				WHILE CHARINDEX('DTS:ExecutableType="STOCK:SEQUENCE"', @SubPlanString1) <> 0
				BEGIN
					INSERT INTO #SUBPLANS1 (PlanText)
					VALUES (Left(@SubPlanString1, CHARINDEX('DTS:ExecutableType="STOCK:SEQUENCE"', @SubPlanString1) - 1));

					SET @SubPlanString1 = Right(@SubPlanString1, Len(@SubPlanString1) - CHARINDEX('DTS:ExecutableType="STOCK:SEQUENCE"', @SubPlanString1));
				END

				--select @SubPlanString1
				INSERT INTO #SUBPLANS1 (PlanText)
				VALUES ('D' + @SubPlanString1);
			END
	

		--	IF @Subplan1 like '%"STOCK:SEQUENCE" DTS:Disabled=%' -- For multiple databases in the parameter
		--	BEGIN
		--		SET @SubPlanString1 = @SubPlan1;

		--		WHILE CHARINDEX('"STOCK:SEQUENCE" DTS:Disabled=', @SubPlanString1) <> 0
		--		BEGIN
		--			INSERT INTO #SUBPLANS1 (PlanText)
		--			VALUES (Left(@SubPlanString1, CHARINDEX('"STOCK:SEQUENCE" DTS:Disabled=', @SubPlanString1)));
		--			select 'asdf', (Left(@SubPlanString1, CHARINDEX('"STOCK:SEQUENCE" DTS:Disabled=', @SubPlanString1)))
		--			SET @SubPlanString1 = Right(@SubPlanString1, Len(@SubPlanString1) - CHARINDEX('DTS:CreationName="STOCK:SEQUENCE" DTS:Disabled=', @SubPlanString1));
		--		END

		--		select '@SubPlanString1', @SubPlanString1
		--		INSERT INTO #SUBPLANS1 (PlanText)
		--		VALUES ('D' + @SubPlanString1);
		--	END
		--END

		DELETE
		FROM #SUBPLANS1
		WHERE id = (
				SELECT MIN(id)
				FROM #SUBPLANS1
				)
	END
END
	--Delete from #SUBPLANS1 where id = (select MAX(id) from #SUBPLANS1)
	-- Part 2 Delimit
	DECLARE @SubPlan2 VARCHAR(max)
		,@SubPlanString2 VARCHAR(max)
		,@ID2 INT

	SET @ID2 = 1

	WHILE @ID2 <= (
			SELECT MAX(ID)
			FROM #SUBPLANS1
			)
	BEGIN
		SELECT @SubPlan2 = [PlanText]
		FROM #SUBPLANS1
		WHERE id = @ID2

		SET @ID2 = @ID2 + 1

		if @debug = 1
		begin
		select 'subplans1', * FROM #SUBPLANS1
		select 'subplan2', @subplan2
		end

		IF @version <= 10
		BEGIN
			IF @SubPlan2 IS NOT NULL
			BEGIN
				IF CHARINDEX('<DTS:Executable DTS:ExecutableType="STOCK:SEQUENCE">', @SubPlan2) <> 0 -- For multiple databases in the parameter
				BEGIN
					SET @SubPlanString2 = @SubPlan2;
					SET @SubPlanString2 = Right(@SubPlanString2, Len(@SubPlanString2) - CHARINDEX('<DTS:Executable DTS:ExecutableType="STOCK:SEQUENCE">', @SubPlanString2));

					INSERT INTO #SUBPLANS2 (PlanText)
					VALUES (@SubPlanString2);
				END
			END

			-- Grab SubPlan Name
			UPDATE [#SUBPLANS2]
			SET SubPlanName = Substring(Reverse(substring(Reverse([PlanText]), 1, CHARINDEX('>"emaNtcejbO"=emaN:STD ytreporP:STD<', Reverse([PlanText])) - 1)), 1, CHARINDEX('</DTS:Property>', Reverse(substring(Reverse([PlanText]), 1, CHARINDEX('>"emaNtcejbO"=emaN:STD ytreporP:STD<', Reverse([PlanText])) - 1))) - 1)
		END

		IF @version >= 11
		BEGIN

		IF @debug = 1
		begin
			SELECT '@subplan2'
				,@subplan2
				,CHARINDEX('DTS:ExecutableType="STOCK:SEQUENCE" ', @SubPlan2)
				,Right(@SubPlanString2, Len(@SubPlanString2) - CHARINDEX('DTS:ExecutableType="STOCK:SEQUENCE"', @SubPlanString2))
				,*
			FROM #SUBPLANS1
		end

			IF @SubPlan2 IS NOT NULL
			BEGIN
			
				IF @SubPlan2 like '%DTS:ExecutableType="STOCK:SEQUENCE"%' -- For multiple databases in the parameter
				BEGIN
				
					if @debug =1
					begin
					select 'subplan2', @SubPlan2
					end

					SET @SubPlanString2 = @SubPlan2;
					
					if @debug =1
					begin
					select 'subplanstring2', @SubPlanString2
					end

					SET @SubPlanString2 = Right(@SubPlanString2, Len(@SubPlanString2) - CHARINDEX('DTS:ExecutableType="STOCK:SEQUENCE"', @SubPlanString2));

					INSERT INTO #SUBPLANS2 (PlanText)
					VALUES (@SubPlanString2);

				END

				IF @debug = 1
	begin
				SELECT '#Subplans2', *
				FROM #SUBPLANS2
				end
			END
-----------
			-- Grab SubPlan Name

			UPDATE [#SUBPLANS2]
			SET SubPlanName = substring(plantext, CHARINDEX('DTS:ObjectName="', [PlanText]) + 16, (CHARINDEX('">', [PlanText])) - (CHARINDEX('DTS:ObjectName="', [PlanText]) + 16))

			
			UPDATE [#SUBPLANS2]
			SET SubPlanName = LEFT(SubPlanName, CHARINDEX('" DTS:DTSID', SubPlanName)-1)
			where SubPlanName like '%" DTS:DTSID%'
			
			
			IF @debug = 1
	begin
			SELECT '#Subplans2', *
			FROM #SUBPLANS2
			end
		END
	END

	--select * from #SUBPLANS2
	-- Part 3 Delimit
	DECLARE @SubPlan3 VARCHAR(max)
		,@SubPlanString3 VARCHAR(max)
		,@ID3 INT

	SET @ID3 = 1

	WHILE @ID3 <= (
			SELECT MAX(ID)
			FROM #SUBPLANS2
			)
	BEGIN
		SELECT @SubPlan3 = [PlanText]
		FROM #SUBPLANS2
		WHERE id = @ID3

		IF @SubPlan3 IS NOT NULL
		BEGIN
			IF @version <= 10
			BEGIN
				IF CHARINDEX('<DTS:Executable DTS:ExecutableType=', @SubPlan3) <> 0 -- For multiple databases in the parameter
				BEGIN
					SET @SubPlanString3 = @SubPlan3;

					WHILE CHARINDEX('<DTS:Executable DTS:ExecutableType=', @SubPlanString3) <> 0
					BEGIN
						INSERT INTO #MaintTask1 (
							SubPlanID
							,PlanText
							)
						VALUES (
							@ID3
							,Left(@SubPlanString3, CHARINDEX('<DTS:Executable DTS:ExecutableType=', @SubPlanString3) - 1)
							);

						SET @SubPlanString3 = Right(@SubPlanString3, Len(@SubPlanString3) - CHARINDEX('<DTS:Executable DTS:ExecutableType=', @SubPlanString3));
					END

					INSERT INTO #MaintTask1 (
						SubPlanID
						,PlanText
						)
					VALUES (
						@ID3
						,@SubPlanString3
						);
				END
			END

			IF @version >= 11
			BEGIN
				IF CHARINDEX('DTS:ExecutableType="Micro', @SubPlan3) <> 0 -- For multiple databases in the parameter
				BEGIN
					SET @SubPlanString3 = @SubPlan3;

					WHILE CHARINDEX('DTS:ExecutableType="Micro', @SubPlanString3) <> 0
					BEGIN
						INSERT INTO #MaintTask1 (
							SubPlanID
							,PlanText
							)
						VALUES (
							@ID3
							,'D' + Left(@SubPlanString3, CHARINDEX('DTS:ExecutableType="Micro', @SubPlanString3) - 1)
							);

						SET @SubPlanString3 = Right(@SubPlanString3, Len(@SubPlanString3) - CHARINDEX('DTS:ExecutableType="Micro', @SubPlanString3));
					END

					INSERT INTO #MaintTask1 (
						SubPlanID
						,PlanText
						)
					VALUES (
						@ID3
						,'D' + @SubPlanString3
						);
				END
			END

		END

		--DELETE
		--FROM #MaintTask1
		--WHERE id = (
		--		SELECT MIN(id)
		--		FROM #MaintTask1
		--		WHERE SubPlanID = @ID3
		--		)

		SET @ID3 = @ID3 + 1
	END

	--select  replace(SUBSTRING(PlanText, 1, charindex('" DTS:LocaleID', PlanText)-1),'DTS:ExecutableType="Microsoft.','') as asdf from #MaintTask1
	IF @version >= 11
		--Grab TaskType
		UPDATE #MaintTask1
		SET TaskType = replace(SUBSTRING(PlanText, 1, charindex('" DTS:LocaleID', PlanText) - 1), 'DTS:ExecutableType="Microsoft.', '')
	ELSE
	UPDATE #MaintTask1
		SET TaskType = replace(SUBSTRING(PlanText, 1, charindex(',', PlanText) - 1), 'DTS:Executable DTS:ExecutableType="Microsoft.SqlServer.Management.DatabaseMaintenance.', '')
	where plantext like '%DTS:Executable DTS:ExecutableType="Microsoft.SqlServer.Management.DatabaseMaintenance.%'

	UPDATE #MaintTask1
	SET TaskType = replace(substring(TaskType, 0, charindex(',', TaskType)), 'SqlServer.Management.DatabaseMaintenance.', '') from #MaintTask1
	where tasktype like '%SqlServer.Management.DatabaseMaintenance.%'
	
	UPDATE #MaintTask1
	SET TaskType = replace(TaskType, '" DTS:FailParentOnFailure="True', '') from #MaintTask1
	where tasktype like '%" DTS:FailParentOnFailure="True%'

	-- Grab TaskDisabled
	IF @version >= 11
		UPDATE #MaintTask1
		SET TaskEnabled = 'No'
		WHERE PlanText like '%DTS:Disabled=True%'
	ELSE
		UPDATE #MaintTask1
		SET TaskEnabled = 'No'
		WHERE SUBSTRING(PlanText, CHARINDEX('<DTS:Property DTS:Name="Disabled">', PlanText) + LEN('<DTS:Property DTS:Name="Disabled">'), 1) = 1

	-- Grab Ignore Database State (2008+ only)
	IF @version >= 11
		UPDATE #MaintTask1
		SET IgnoreDatabaseState = 'Yes'
		WHERE PlanText like '%SQLTask:IgnoreDatabasesInNotOnlineState="True"%'
	ELSE IF @Version = 10
		UPDATE #MaintTask1
		SET IgnoreDatabaseState = 'Yes'
		WHERE SUBSTRING(PlanText, CHARINDEX('SQLTask:IgnoreDatabasesInNotOnlineState="', PlanText) + LEN('SQLTask:IgnoreDatabasesInNotOnlineState="'), 1) = 'T'

	-- Grab TaskName
	IF @version >= 11
	BEGIN
		UPDATE #MaintTask1
		SET TaskName = SUBSTRING(SUBSTRING(PlanText, CHARINDEX('TaskName="', PlanText) + LEN('TaskName="'), LEN(PlanText)), 1, CHARINDEX('"', (SUBSTRING(PlanText, CHARINDEX('TaskName="', PlanText) + LEN('TaskName="'), LEN(PlanText)))) - 1)
		WHERE plantext like '%TaskName="%'

		UPDATE #MaintTask1
		SET TaskName = ''
		WHERE taskname IS NULL
	END
	ELSE
		UPDATE #MaintTask1
		SET TaskName = SUBSTRING(SUBSTRING(PlanText, CHARINDEX('SQLTask:TaskName="', PlanText) + LEN('SQLTask:TaskName="'), LEN(PlanText)), 1, CHARINDEX('"', (SUBSTRING(PlanText, CHARINDEX('SQLTask:TaskName="', PlanText) + LEN('SQLTask:TaskName="'), LEN(PlanText)))) - 1)

	-- Grab Database SelectionType
	UPDATE #MaintTask1
	SET DatabaseSelectionType = substring(PlanText, charindex('SQLTask:DatabaseSelectionType="', PlanText) + len('SQLTask:DatabaseSelectionType="'), 1)
	WHERE charindex('SQLTask:DatabaseSelectionType="', PlanText) > 0

	UPDATE #MaintTask1
	SET DatabaseSelectionType = 'N/A'
		,IgnoreDatabaseState = 'N/A'
	WHERE DatabaseSelectionType IS NULL

	IF @version >= 11
		UPDATE #MaintTask1
		SET [DatabaseSelectionType] = 'These Databases: ' + LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(PlanText, CHARINDEX('<SQLTask:SelectedDatabases SQLTask:DatabaseName="', PlanText), CHARINDEX('</SQLTask:SqlTaskData>', PlanText) - CHARINDEX('<SQLTask:SelectedDatabases SQLTask:DatabaseName="', PlanText)), '"/>', '],'), '<SQLTask:SelectedDatabases SQLTask:DatabaseName="', '['), CHAR(13), ''), CHAR(10), ''), ' ', '')))
		WHERE [DatabaseSelectionType] = '4'
			AND plantext like '%</SQLTask:SqlTaskData>%'
	ELSE
		UPDATE #MaintTask1
		SET [DatabaseSelectionType] = 'These Databases: ' + REPLACE(REPLACE(SUBSTRING(PlanText, CHARINDEX('<SQLTask:SelectedDatabases SQLTask:DatabaseName="', PlanText), CHARINDEX('<SQLTask:BackupDestinationList', PlanText) - CHARINDEX('<SQLTask:SelectedDatabases SQLTask:DatabaseName="', PlanText)), '"/>', '],'), '<SQLTask:SelectedDatabases SQLTask:DatabaseName="', '[')
		WHERE [DatabaseSelectionType] = '4'
			AND CHARINDEX('<SQLTask:BackupDestinationList', PlanText) > 0

	UPDATE #MaintTask1
	SET [DatabaseSelectionType] = 'These Databases: ' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(PlanText, CHARINDEX('<SQLTask:SelectedDatabases SQLTask:DatabaseName="', PlanText), CHARINDEX('</SQLTask:SqlTaskData></DTS:ObjectData>', PlanText) - CHARINDEX('<SQLTask:SelectedDatabases SQLTask:DatabaseName="', PlanText)), '"/>', '],'), '<SQLTask:SelectedDatabases SQLTask:DatabaseName="', '['), CHAR(13), ''), CHAR(10), ''), ' ', '')
	WHERE [DatabaseSelectionType] = '4'

	UPDATE #MaintTask1
	SET [DatabaseSelectionType] = LEFT([DatabaseSelectionType], LEN([DatabaseSelectionType]) - 1)
	WHERE LEFT([DatabaseSelectionType], LEN('These Databases:')) = 'These Databases:'

	UPDATE #MaintTask1
	SET DatabaseSelectionType = CASE 
			WHEN DatabaseSelectionType = 1
				THEN 'All Databases'
			WHEN DatabaseSelectionType = 2
				THEN 'All System Databases'
			WHEN DatabaseSelectionType = 3
				THEN 'All User Databases'
			END
	WHERE DatabaseSelectionType IN (
			'1'
			,'2'
			,'3'
			)

	-- Grab SQL Agent Task Option Info
	UPDATE #MaintTask1
	SET TaskOptions = 'Start job: ''' + RTRIM(REPLACE(SUBSTRING(PlanText, CHARINDEX('SQLTask:AgentJobID="', PlanText) + LEN('SQLTask:AgentJobID="'), CHARINDEX('xmlns:SQLTask="', PlanText, CHARINDEX('SQLTask:AgentJobID="', PlanText)) - (CHARINDEX('SQLTask:AgentJobID="', PlanText) + LEN('SQLTask:AgentJobID="')) + 6), '" xmlns:', '')) + ''''
	WHERE TaskType = 'DbMaintenanceExecuteAgentJobTask'

	UPDATE #MaintTask1
	SET TaskOptions = LEFT(TaskOptions, LEN(TaskOptions) - 1)
	WHERE LEFT(TaskOptions, LEN('Starts job(s): ')) = 'Starts job(s): '

	-- Grab SQL for Execute SQL task
	IF @version >= 11
		UPDATE #MaintTask1
		SET TaskOptions = 'Execute SQL: ' + REPLACE((RTRIM(REPLACE(SUBSTRING(PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText) + LEN('SQLTask:SqlStatementSource="'), CHARINDEX(':SQLTask="www.microsoft.com/sqlserver/dts/tasks/sqltask">', PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText)) - (CHARINDEX('SQLTask:SqlStatementSource="', PlanText) + LEN('SQLTask:SqlStatementSource="')) + 18), ':SQLTask="www.microsoft.com/sqlserver/dts/tasks/sqltask">', ';'))), '&#xA;', CHAR(10) + CHAR(10))
		WHERE TaskType IN (
				'DbMaintenanceTSQLExecuteTask'
				,'ExecuteSQLTask'
				)
			AND NOT CHARINDEX(':SQLTask="www.microsoft.com/sqlserver/dts/tasks/sqltask">', PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText)) = 0
	ELSE
		UPDATE #MaintTask1
		SET TaskOptions = 'Execute SQL: ' + REPLACE((RTRIM(REPLACE(SUBSTRING(PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText) + LEN('SQLTask:SqlStatementSource="'), CHARINDEX('" SQLTask:CodePage', PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText)) - (CHARINDEX('SQLTask:SqlStatementSource="', PlanText) + LEN('SQLTask:SqlStatementSource="')) + 18), '" SQLTask:CodePage', ';'))), '&#xA;', CHAR(10) + CHAR(10))
		WHERE TaskType = 'DbMaintenanceTSQLExecuteTask'
			AND NOT CHARINDEX('" SQLTask:CodePage', PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText)) = 0

	UPDATE #MaintTask1
	SET TaskOptions = 'Execute SQL: ' + REPLACE((RTRIM(REPLACE(SUBSTRING(PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText) + LEN('SQLTask:SqlStatementSource="'), CHARINDEX('" SQLTask:ResultType="', PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText)) - (CHARINDEX('SQLTask:SqlStatementSource="', PlanText) + LEN('SQLTask:SqlStatementSource="')) + 18), '" SQLTask:CodePage', ';'))), '&#xA;', CHAR(10) + CHAR(10))
	WHERE TaskType IN (
			'DbMaintenanceTSQLExecuteTask'
			,'ExecuteSQLTask'
			)
		AND NOT CHARINDEX('" SQLTask:ResultType="', PlanText, CHARINDEX('SQLTask:SqlStatementSource="', PlanText)) = 0

	-- Grab ReOrg Task Info
	UPDATE #MaintTask1
	SET TaskOptions = 'Compact Large Objects = ' + CASE 
			WHEN (RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:CompactLargeObjects="', PlanText) + LEN('SQLTask:CompactLargeObjects="'), CHARINDEX('" xmlns:SQLTask="', PlanText, CHARINDEX('SQLTask:CompactLargeObjects="', PlanText)) - (CHARINDEX('SQLTask:CompactLargeObjects="', PlanText) + LEN('SQLTask:CompactLargeObjects="'))))) = 'True'
				THEN 'Yes'
			ELSE 'No'
			END
	WHERE TaskType = 'DbMaintenanceDefragmentIndexTask'

	-- Grab Integrity Check Task Info
	UPDATE #MaintTask1
	SET TaskOptions = 'Include Indexes = ' + CASE 
			WHEN (RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:IncludeIndexes="', PlanText) + LEN('SQLTask:IncludeIndexes="'), CHARINDEX('" xmlns:SQLTask="', PlanText, CHARINDEX('SQLTask:IncludeIndexes="', PlanText)) - (CHARINDEX('SQLTask:IncludeIndexes="', PlanText) + LEN('SQLTask:IncludeIndexes="'))))) = 'True'
				THEN 'Yes'
			ELSE 'No'
			END
	WHERE TaskType = 'DbMaintenanceCheckIntegrityTask'

	-- Grab Index Rebuild Task Option Info
	DECLARE @RebuildTaskID INT
		,@RebuildOptions VARCHAR(1000)

	SET @RebuildTaskID = (
			SELECT MIN(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceReindexTask'
			)

	WHILE @RebuildTaskID <= (
			SELECT max(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceReindexTask'
			)
	BEGIN
		-- Tasks Info
		-- UseOriginalAmount = Original fill factor
		-- Percentage = Change %
		-- Sort = Sort in Tempdb
		-- KeepOnline = Online Index Rebuild
		SELECT @RebuildOptions = CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:UseOriginalAmount="', PlanText) + LEN('SQLTask:UseOriginalAmount="'), 1)) = 'T'
					THEN 'Original fill factor'
				ELSE 'Change free space to: ' + Replace(SUBSTRING(PlanText, CHARINDEX('SQLTask:Percentage="', PlanText) + LEN('SQLTask:Percentage="'), 3), '"', '') + '%'
				END
		FROM #MaintTask1
		WHERE id = @RebuildTaskID

		SET @RebuildOptions = @RebuildOptions + ', '

		SELECT @RebuildOptions = @RebuildOptions + CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:KeepOnline="', PlanText) + LEN('SQLTask:KeepOnline="'), 1)) = 'T'
					THEN 'Online Rebuild'
				ELSE 'Offline Rebuild'
				END
		FROM #MaintTask1
		WHERE id = @RebuildTaskID

		SELECT @RebuildOptions = @RebuildOptions + CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:Sort="', PlanText) + LEN('SQLTask:Sort="'), 1)) = 'T'
					THEN ', Sort in Tempdb'
				ELSE ''
				END
		FROM #MaintTask1
		WHERE id = @RebuildTaskID

		UPDATE #MaintTask1
		SET TaskOptions = @RebuildOptions
		WHERE id = @RebuildTaskID

		SET @RebuildTaskID = (
				SELECT CASE 
						WHEN MIN(id) > 1
							THEN MIN(id)
						ELSE @RebuildTaskID + 1
						END
				FROM #MaintTask1
				WHERE TaskType = 'DbMaintenanceReindexTask'
					AND id > @RebuildTaskID
				)
	END

	-- Grab History Cleanup Task Option Info
	DECLARE @HistoryTaskID INT
		,@HistoryOptions VARCHAR(1000)

	SET @HistoryTaskID = (
			SELECT MIN(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceHistoryCleanupTask'
			)

	WHILE @HistoryTaskID <= (
			SELECT max(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceHistoryCleanupTask'
			)
	BEGIN
		-- Tasks Info
		-- RemoveBackupRestoreHistory 
		-- RemoveAgentHistory 
		-- RemoveDbMaintHistory 
		-- RemoveOlderThan 
		-- TimeUnitsType = 5=Hours, 0=Days, 1=Weeks, 2=Months, 3=Years
		SET @HistoryOptions = 'Remove '

		SELECT @HistoryOptions = @HistoryOptions + CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:RemoveBackupRestoreHistory="', PlanText) + LEN('SQLTask:RemoveBackupRestoreHistory="'), 1)) = 'T'
					THEN 'Backup and Restore'
				ELSE ''
				END
		FROM #MaintTask1
		WHERE id = @HistoryTaskID

		IF LEN(@HistoryOptions) > 6
			SET @HistoryOptions = @HistoryOptions + '/'

		SELECT @HistoryOptions = @HistoryOptions + CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:RemoveAgentHistory="', PlanText) + LEN('SQLTask:RemoveAgentHistory="'), 1)) = 'T'
					THEN 'Agent'
				ELSE ''
				END
		FROM #MaintTask1
		WHERE id = @HistoryTaskID

		IF LEN(@HistoryOptions) > 6
			SET @HistoryOptions = @HistoryOptions + '/'

		SELECT @HistoryOptions = @HistoryOptions + CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:RemoveDbMaintHistory="', PlanText) + LEN('SQLTask:RemoveDbMaintHistory="'), 1)) = 'T'
					THEN 'DB Maint'
				ELSE ''
				END
		FROM #MaintTask1
		WHERE id = @HistoryTaskID

		IF LEN(@HistoryOptions) > 6
			SELECT @HistoryOptions = substring(@HistoryOptions, 1, LEN(@HistoryOptions)) + 'History older than '

		SELECT @HistoryOptions = @HistoryOptions + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:RemoveOlderThan="', PlanText) + LEN('SQLTask:RemoveOlderThan="'), CHARINDEX('" SQLTask:TimeUnitsType', PlanText, CHARINDEX('SQLTask:RemoveOlderThan="', PlanText)) - (CHARINDEX('SQLTask:RemoveOlderThan="', PlanText) + LEN('SQLTask:RemoveOlderThan="'))))
		FROM #MaintTask1
		WHERE id = @HistoryTaskID

		SELECT @HistoryOptions = @HistoryOptions + CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1)) = '5'
					THEN ' Hours'
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1)) = '0'
					THEN ' Days'
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1)) = '1'
					THEN ' Weeks'
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1)) = '2'
					THEN ' Months'
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1)) = '3'
					THEN ' Years'
				ELSE ''
				END
		FROM #MaintTask1
		WHERE id = @HistoryTaskID

		UPDATE #MaintTask1
		SET TaskOptions = @HistoryOptions
		WHERE id = @HistoryTaskID

		--Select @HistoryOptions
		SET @HistoryTaskID = (
				SELECT CASE 
						WHEN MIN(id) > 1
							THEN MIN(id)
						ELSE @HistoryTaskID + 1
						END
				FROM #MaintTask1
				WHERE TaskType = 'DbMaintenanceHistoryCleanupTask'
					AND id > @HistoryTaskID
				)
	END

	-- Grab Update Stats Task Option Info
	DECLARE @UpdateStatsTaskID INT
		,@UpdateStatsOptions VARCHAR(1000)

	SET @UpdateStatsTaskID = (
			SELECT MIN(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceUpdateStatisticsTask'
			)

	WHILE @UpdateStatsTaskID <= (
			SELECT max(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceUpdateStatisticsTask'
			)
	BEGIN
		-- Tasks Info
		-- UpdateStatisticsType = 2=All Existing Stats, 1=Column Stats Only, 0=Index Stats Only
		-- UpdateScanType = 3=Full Scan, 1=Percent, 2=Rows
		-- UpdateSampleValue = Sample Value
		SELECT @UpdateStatsOptions = CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:UpdateStatisticsType="', PlanText) + LEN('SQLTask:UpdateStatisticsType="'), 1)) = '2'
					THEN 'Update All existing stats'
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:UpdateStatisticsType="', PlanText) + LEN('SQLTask:UpdateStatisticsType="'), 1)) = '1'
					THEN 'Update Column stats only'
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:UpdateStatisticsType="', PlanText) + LEN('SQLTask:UpdateStatisticsType="'), 1)) = '0'
					THEN 'Update Index stats only'
				END
		FROM #MaintTask1
		WHERE id = @UpdateStatsTaskID

		SET @UpdateStatsOptions = @UpdateStatsOptions + ' with a scan type of '

		SELECT @UpdateStatsOptions = @UpdateStatsOptions + CASE 
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:UpdateScanType="', PlanText) + LEN('SQLTask:UpdateScanType="'), 1)) = '1'
					THEN RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:UpdateSampleValue="', PlanText) + LEN('SQLTask:UpdateSampleValue="'), CHARINDEX('" xmlns:SQLTask="', PlanText, CHARINDEX('SQLTask:UpdateSampleValue="', PlanText)) - (CHARINDEX('SQLTask:UpdateSampleValue="', PlanText) + LEN('SQLTask:UpdateSampleValue="')))) + '%'
				WHEN (SUBSTRING(PlanText, CHARINDEX('SQLTask:UpdateScanType="', PlanText) + LEN('SQLTask:UpdateScanType="'), 1)) = '2'
					THEN RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:UpdateSampleValue="', PlanText) + LEN('SQLTask:UpdateSampleValue="'), CHARINDEX('" xmlns:SQLTask="', PlanText, CHARINDEX('SQLTask:UpdateSampleValue="', PlanText)) - (CHARINDEX('SQLTask:UpdateSampleValue="', PlanText) + LEN('SQLTask:UpdateSampleValue="')))) + ' Rows'
				ELSE 'Full'
				END
		FROM #MaintTask1
		WHERE id = @UpdateStatsTaskID

		UPDATE #MaintTask1
		SET TaskOptions = @UpdateStatsOptions
		WHERE id = @UpdateStatsTaskID

		SET @UpdateStatsTaskID = (
				SELECT CASE 
						WHEN MIN(id) > 1
							THEN MIN(id)
						ELSE @UpdateStatsTaskID + 1
						END
				FROM #MaintTask1
				WHERE TaskType = 'DbMaintenanceUpdateStatisticsTask'
					AND id > @UpdateStatsTaskID
				)
	END

	-- Grab Database Shrink Task Option Info
	DECLARE @ShrinkTaskID INT
		,@ShrinkOptions VARCHAR(1000)

	SET @ShrinkTaskID = (
			SELECT MIN(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceShrinkTask'
			)

	WHILE @ShrinkTaskID <= (
			SELECT max(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceShrinkTask'
			)
	BEGIN
		-- Tasks Info
		-- DatabaseSizeLimit = Grows Beyond MB
		-- DatabasePercentLimit = Percent to leave free
		-- DatabaseReturnFreeSpace = Return Free Space to O/S (True) or leave in database (False)
		SELECT @ShrinkOptions = 'Shrink Database if larger then ' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:DatabaseSizeLimit="', PlanText) + LEN('SQLTask:DatabaseSizeLimit="'), CHARINDEX('" SQLTask:DatabasePercentLimit="', PlanText, CHARINDEX('SQLTask:DatabaseSizeLimit="', PlanText)) - (CHARINDEX('SQLTask:DatabaseSizeLimit="', PlanText) + LEN('SQLTask:DatabaseSizeLimit="')))) + 'MB'
		FROM #MaintTask1
		WHERE id = @ShrinkTaskID

		SELECT @ShrinkOptions = @ShrinkOptions + ', Leave' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:DatabasePercentLimit="', PlanText) + LEN('SQLTask:DatabasePercentLimit="'), CHARINDEX('" SQLTask:DatabaseReturnFreeSpace="', PlanText, CHARINDEX('SQLTask:DatabasePercentLimit="', PlanText)) - (CHARINDEX('SQLTask:DatabasePercentLimit="', PlanText) + LEN('SQLTask:DatabasePercentLimit="')))) + '% free in the database'
		FROM #MaintTask1
		WHERE id = @ShrinkTaskID

		SELECT @ShrinkOptions = @ShrinkOptions + ', ' + CASE 
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:DatabaseReturnFreeSpace="', PlanText) + LEN('SQLTask:DatabaseReturnFreeSpace="'), 1) = 'T'
					THEN 'Return freed space to O/S'
				ELSE 'Leave freed space in database'
				END
		FROM #MaintTask1
		WHERE id = @ShrinkTaskID

		UPDATE #MaintTask1
		SET TaskOptions = @ShrinkOptions
		WHERE id = @ShrinkTaskID

		SET @ShrinkTaskID = (
				SELECT CASE 
						WHEN MIN(id) > 1
							THEN MIN(id)
						ELSE @ShrinkTaskID + 1
						END
				FROM #MaintTask1
				WHERE TaskType = 'DbMaintenanceShrinkTask'
					AND id > @ShrinkTaskID
				)
	END

	-- Grab File Cleanup Task Option Info
	DECLARE @MaintCleanupTaskID INT
		,@MaintCleanupOptions VARCHAR(2000)

	SET @MaintCleanupTaskID = (
			SELECT MIN(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceFileCleanupTask'
			)

	WHILE @MaintCleanupTaskID <= (
			SELECT max(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceFileCleanupTask'
			)
	BEGIN
		-- Tasks Info
		-- FileTypeSelected = Backups=0, Report Files=1 
		-- FilePath = Specific File
		-- FolderPath = Folder to check
		-- CleanSubFolders = Check SubFolders (T/F)
		-- FileExtension
		-- AgeBased = Delete file based on age (T/F)
		-- DeleteSpecificFile = Delete specific file (T/F) *Requires FilePath
		-- TimeUnitsType  = 5=Hours, 0=Days, 1=Weeks, 2=Months, 3=Years
		-- RemoveOlderThan
		SELECT @MaintCleanupOptions = CASE 
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:FileTypeSelected="', PlanText) + LEN('SQLTask:FileTypeSelected="'), 1) = '1'
					THEN 'Delete Maintenance plan text report(s)'
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:FileTypeSelected="', PlanText) + LEN('SQLTask:FileTypeSelected="'), 1) = '0'
					THEN 'Delete file(s)'
				END
		FROM #MaintTask1
		WHERE id = @MaintCleanupTaskID

		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:DeleteSpecificFile="', PlanText) + LEN('SQLTask:DeleteSpecificFile="'), 1)
				FROM #MaintTask1
				WHERE id = @MaintCleanupTaskID
				) = 'T' -- Check for DeleteSpecificFile 
			SELECT @MaintCleanupOptions = 'Delete specific file=' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:FilePath="', PlanText) + LEN('SQLTask:FilePath="'), CHARINDEX('" SQLTask:FolderPath="', PlanText, CHARINDEX('SQLTask:FilePath="', PlanText)) - (CHARINDEX('SQLTask:FilePath="', PlanText) + LEN('SQLTask:FilePath="'))))
			FROM #MaintTask1
			WHERE id = @MaintCleanupTaskID

		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:AgeBased="', PlanText) + LEN('SQLTask:AgeBased="'), 1)
				FROM #MaintTask1
				WHERE id = @MaintCleanupTaskID
				) = 'T'
		BEGIN
			SELECT @MaintCleanupOptions = @MaintCleanupOptions + ', When file(s) older than '

			SELECT @MaintCleanupOptions = @MaintCleanupOptions + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:RemoveOlderThan="', PlanText) + LEN('SQLTask:RemoveOlderThan="'), CHARINDEX('" SQLTask:TimeUnitsType="', PlanText, CHARINDEX('SQLTask:RemoveOlderThan="', PlanText)) - (CHARINDEX('SQLTask:RemoveOlderThan="', PlanText) + LEN('SQLTask:RemoveOlderThan="'))))
			FROM #MaintTask1
			WHERE id = @MaintCleanupTaskID

			SELECT @MaintCleanupOptions = @MaintCleanupOptions + CASE 
					WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1) = '5'
						THEN ' Hours'
					WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1) = '0'
						THEN ' Days'
					WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1) = '1'
						THEN ' Weeks'
					WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1) = '2'
						THEN ' Months'
					WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:TimeUnitsType="', PlanText) + LEN('SQLTask:TimeUnitsType="'), 1) = '3'
						THEN ' Years'
					END
			FROM #MaintTask1
			WHERE id = @MaintCleanupTaskID
		END

		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:DeleteSpecificFile="', PlanText) + LEN('SQLTask:DeleteSpecificFile="'), 1)
				FROM #MaintTask1
				WHERE id = @MaintCleanupTaskID
				) = 'F' -- Check for DeleteSpecificFile 
		BEGIN
			SELECT @MaintCleanupOptions = @MaintCleanupOptions + ', with extension ''.' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:FileExtension="', PlanText) + LEN('SQLTask:FileExtension="'), CHARINDEX('" SQLTask:AgeBased="', PlanText, CHARINDEX('SQLTask:FileExtension="', PlanText)) - (CHARINDEX('SQLTask:FileExtension="', PlanText) + LEN('SQLTask:FileExtension="')))) + ''''
			FROM #MaintTask1
			WHERE id = @MaintCleanupTaskID

			SELECT @MaintCleanupOptions = @MaintCleanupOptions + ', in folder: ''' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:FolderPath="', PlanText) + LEN('SQLTask:FolderPath="'), CHARINDEX('" SQLTask:CleanSubFolders="', PlanText, CHARINDEX('SQLTask:FolderPath="', PlanText)) - (CHARINDEX('SQLTask:FolderPath="', PlanText) + LEN('SQLTask:FolderPath="')))) + ''''
			FROM #MaintTask1
			WHERE id = @MaintCleanupTaskID

			IF (
					SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:CleanSubFolders="', PlanText) + LEN('SQLTask:CleanSubFolders="'), 1)
					FROM #MaintTask1
					WHERE id = @MaintCleanupTaskID
					) = 'T'
				SELECT @MaintCleanupOptions = @MaintCleanupOptions + ', including first-level subfolders'
		END

		UPDATE #MaintTask1
		SET TaskOptions = @MaintCleanupOptions
		WHERE id = @MaintCleanupTaskID

		SET @MaintCleanupTaskID = (
				SELECT CASE 
						WHEN MIN(id) > 1
							THEN MIN(id)
						ELSE @MaintCleanupTaskID + 1
						END
				FROM #MaintTask1
				WHERE TaskType = 'DbMaintenanceFileCleanupTask'
					AND id > @MaintCleanupTaskID
				)
	END

	-- Grab File Cleanup Task Option Info
	DECLARE @BackupTaskID INT
		,@BackupOptions VARCHAR(2000)

	SET @BackupTaskID = (
			SELECT MIN(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceBackupTask'
			)

	WHILE @BackupTaskID <= (
			SELECT max(id)
			FROM #MaintTask1
			WHERE TaskType = 'DbMaintenanceBackupTask'
			)
	BEGIN
		-- Tasks Info
		-- BackupAction = Full/Diff = 0, Tran =2 
		-- BackupIsIncremental = False = Full, True = Diff
		-- BackupFileGroupsFiles
		-- BackupDeviceType = Disk=2
		-- BackupPhisycalDestinationType = ? stripe?
		-- BackupDestinationType = ? stripe?
		-- BackupDestinationAutoFolderPath = Backup Directory
		-- BackupActionForExistingBackups = Append=0,Overwrite=1
		-- BackupCreateSubFolder = Create in Subfolder
		-- BackupFileExtension = default = bak
		-- BackupVerifyIntegrity
		-- ExpireDate *Requires UseExpiration
		-- RetainDays *Requires UseExpiration
		-- InDays = RetainDays is int days *Requires UseExpiration
		-- UseExpiration
		-- BackupCompressionAction
		-- BackupTailLog
		SELECT @BackupOptions = CASE 
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupAction="', PlanText) + LEN('SQLTask:BackupAction="'), 1) = '2'
					THEN 'Transaction Log Backup'
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupAction="', PlanText) + LEN('SQLTask:BackupAction="'), 1) = 0
					AND SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupIsIncremental="', PlanText) + LEN('SQLTask:BackupIsIncremental="'), 1) = 'T'
					THEN 'Differential Backup'
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupAction="', PlanText) + LEN('SQLTask:BackupAction="'), 1) = 0
					AND SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupIsIncremental="', PlanText) + LEN('SQLTask:BackupIsIncremental="'), 1) = 'F'
					THEN 'Full Backup'
				ELSE 'Full Backup'
				END
		FROM #MaintTask1
		WHERE id = @BackupTaskID

		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupFileGroupsFiles="', PlanText) + LEN('SQLTask:BackupFileGroupsFiles="'), 1)
				FROM #MaintTask1
				WHERE id = @BackupTaskID
				) <> '"' -- Check for Filegroup backups
			SELECT @BackupOptions = @BackupOptions + ' of filegroup(s): ' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupFileGroupsFiles="', PlanText) + LEN('SQLTask:BackupFileGroupsFiles="'), CHARINDEX('" SQLTask:BackupDeviceType="', PlanText, CHARINDEX('SQLTask:BackupFileGroupsFiles="', PlanText)) - (CHARINDEX('SQLTask:BackupFileGroupsFiles="', PlanText) + LEN('SQLTask:BackupFileGroupsFiles="'))))
			FROM #MaintTask1
			WHERE id = @BackupTaskID

		-- BackupDeviceType = Disk=2
		-- BackupPhisycalDestinationType = ? stripe?
		-- BackupDestinationType = ? stripe?
		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupDestinationAutoFolderPath="', PlanText) + LEN('SQLTask:BackupDestinationAutoFolderPath="'), 1)
				FROM #MaintTask1
				WHERE id = @BackupTaskID
				) <> '"'
			SELECT @BackupOptions = @BackupOptions + ', to disk=''' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupDestinationAutoFolderPath="', PlanText) + LEN('SQLTask:BackupDestinationAutoFolderPath="'), CHARINDEX('" SQLTask:BackupActionForExistingBackups="', PlanText, CHARINDEX('SQLTask:BackupDestinationAutoFolderPath="', PlanText)) - (CHARINDEX('SQLTask:BackupDestinationAutoFolderPath="', PlanText) + LEN('SQLTask:BackupDestinationAutoFolderPath="')))) + ''''
			FROM #MaintTask1
			WHERE id = @BackupTaskID



		IF (
				SELECT charindex('SQLTask:BackupDestinationLocation="', PlanText)
				FROM #MaintTask1
				WHERE id = @BackupTaskID
				) > 0
		BEGIN
			SELECT @BackupOptions = @BackupOptions + ', to disk=' + Replace(Replace('''' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupDestinationList SQLTask:BackupDestinationLocation="', PlanText) + LEN('SQLTask:BackupDestinationList SQLTask:BackupDestinationLocation="'), CHARINDEX('"/></SQLTask:SqlTaskData></DTS:ObjectData>', PlanText, CHARINDEX('SQLTask:BackupDestinationList SQLTask:BackupDestinationLocation="', PlanText)) - (CHARINDEX('SQLTask:BackupDestinationList SQLTask:BackupDestinationLocation="', PlanText) + LEN('SQLTask:BackupDestinationList SQLTask:BackupDestinationLocation="')))) + '''', '"/><SQLTask:BackupDestinationList SQLTask:BackupDestinationLocation="', ''', '''), '''1,', '''')
			FROM #MaintTask1
			WHERE id = @BackupTaskID

			SELECT @BackupOptions = @BackupOptions + CASE 
					WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupActionForExistingBackups="', PlanText) + LEN('SQLTask:BackupActionForExistingBackups="'), 1) = '0'
						THEN ',aAppend existing backup'
					WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupActionForExistingBackups="', PlanText) + LEN('SQLTask:BackupActionForExistingBackups="'), 1) = '1'
						THEN ', overwrite existing backup'
					END
			FROM #MaintTask1
			WHERE id = @BackupTaskID
		END

		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupCreateSubFolder="', PlanText) + LEN('SQLTask:BackupCreateSubFolder="'), 1)
				FROM #MaintTask1
				WHERE id = @BackupTaskID
				) = 'T'
			SELECT @BackupOptions = @BackupOptions + ', into their own subfolders'

		SELECT @BackupOptions = @BackupOptions + CASE 
				WHEN LEN(RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupFileExtension="', PlanText) + LEN('SQLTask:BackupFileExtension="'), CHARINDEX('" SQLTask:BackupVerifyIntegrity="', PlanText, CHARINDEX('SQLTask:BackupFileExtension="', PlanText)) - (CHARINDEX('SQLTask:BackupFileExtension="', PlanText) + LEN('SQLTask:BackupFileExtension="'))))) > 0
					THEN ', with extension: ''.' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupFileExtension="', PlanText) + LEN('SQLTask:BackupFileExtension="'), CHARINDEX('" SQLTask:BackupVerifyIntegrity="', PlanText, CHARINDEX('SQLTask:BackupFileExtension="', PlanText)) - (CHARINDEX('SQLTask:BackupFileExtension="', PlanText) + LEN('SQLTask:BackupFileExtension="')))) + ''''
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupFileExtension="', PlanText) + LEN('SQLTask:BackupFileExtension="'), 1) = '"'
					THEN ''
				ELSE ', with extension: ''.bak'''
				END
		FROM #MaintTask1
		WHERE id = @BackupTaskID

		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupVerifyIntegrity="', PlanText) + LEN('SQLTask:BackupVerifyIntegrity="'), 1)
				FROM #MaintTask1
				WHERE id = @BackupTaskID
				) = 'T'
			SELECT @BackupOptions = @BackupOptions + ', with verify backup'

		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:UseExpiration="', PlanText) + LEN('SQLTask:UseExpiration="'), 1)
				FROM #MaintTask1
				WHERE id = @BackupTaskID
				) = 'T' -- Backup Expire
		BEGIN
			SELECT @BackupOptions = @BackupOptions + ', delete backup(s) older than '

			IF (
					SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:InDays="', PlanText) + LEN('SQLTask:InDays="'), 1)
					FROM #MaintTask1
					WHERE id = @BackupTaskID
					) = 'T'
				SELECT @BackupOptions = @BackupOptions + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:RetainDays="', PlanText) + LEN('SQLTask:RetainDays="'), CHARINDEX('" SQLTask:InDays="', PlanText, CHARINDEX('SQLTask:RetainDays="', PlanText)) - (CHARINDEX('SQLTask:RetainDays="', PlanText) + LEN('SQLTask:RetainDays="')))) + ' days'
				FROM #MaintTask1
				WHERE id = @BackupTaskID
			ELSE
				SELECT @BackupOptions = @BackupOptions + '''' + RTRIM(SUBSTRING(PlanText, CHARINDEX('SQLTask:ExpireDate="', PlanText) + LEN('SQLTask:ExpireDate="'), CHARINDEX('" SQLTask:RetainDays="', PlanText, CHARINDEX('SQLTask:ExpireDate="', PlanText)) - (CHARINDEX('SQLTask:ExpireDate="', PlanText) + LEN('SQLTask:ExpireDate="')))) + ''''
				FROM #MaintTask1
				WHERE id = @BackupTaskID
		END

		SELECT @BackupOptions = @BackupOptions + CASE 
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupCompressionAction="', PlanText) + LEN('SQLTask:BackupCompressionAction="'), 1) = '1'
					THEN ', with backup compression'
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupCompressionAction="', PlanText) + LEN('SQLTask:BackupCompressionAction="'), 1) = '2'
					THEN ', with no backup compression'
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupCompressionAction="', PlanText) + LEN('SQLTask:BackupCompressionAction="'), 1) = '0'
					AND (
						SELECT value_in_use
						FROM master.sys.configurations
						WHERE name = 'backup compression default'
						) = 0
					THEN ', with no backup compression'
				WHEN SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupCompressionAction="', PlanText) + LEN('SQLTask:BackupCompressionAction="'), 1) = '0'
					AND (
						SELECT value_in_use
						FROM master.sys.configurations
						WHERE name = 'backup compression default'
						) = 1
					THEN ', with backup compression'
				ELSE ''
				END
		FROM #MaintTask1
		WHERE id = @BackupTaskID

		IF (
				SELECT SUBSTRING(PlanText, CHARINDEX('SQLTask:BackupTailLog="', PlanText) + LEN('SQLTask:BackupTailLog="'), 1)
				FROM #MaintTask1
				WHERE id = @BackupTaskID
				) = 'T'
			SELECT @BackupOptions = @BackupOptions + ', only backup the tail of the log'

		UPDATE #MaintTask1
		SET TaskOptions = @BackupOptions
		WHERE id = @BackupTaskID

		SET @BackupTaskID = (
				SELECT CASE 
						WHEN MIN(id) > 1
							THEN MIN(id)
						ELSE @BackupTaskID + 1
						END
				FROM #MaintTask1
				WHERE TaskType = 'DbMaintenanceBackupTask'
					AND id > @BackupTaskID
				)
	END

	-- Grab Server Connection Info
	UPDATE #MaintTask1
	SET SERVER = @@servername

	IF @debug = 1
	begin

	SELECT 'mainttask1Sum', *
	FROM #MaintTask1

	SELECT 'maintplanconnections2SUM',*
	FROM #MaintPlanConnections2

	SELECT 'subplans2SUM', *
	FROM #SUBPLANS2

	select '@MaintPlanNameSUM', @MaintPlanName
	end

	-- Report
	INSERT INTO #MaintPlansReport
	SELECT distinct LTRIM(RTRIM(@MaintPlanName))
		,LTRIM(RTRIM(b.SubPlanName))
		,LTRIM(RTRIM(c.Server))
		,LTRIM(RTRIM(c.TaskName))
		,LTRIM(RTRIM(c.TaskType))
		,LTRIM(RTRIM(c.TaskEnabled))
		,LTRIM(RTRIM(c.DatabaseSelectionType))
		,LTRIM(RTRIM(c.IgnoreDatabaseState))
		,LTRIM(RTRIM(c.TaskOptions))
	FROM dbo.#SUBPLANS2 b
	LEFT JOIN [#MaintTask1] c ON c.SubPlanID = b.id
	--left JOIN #MaintPlanConnections2 d ON d.ConnectionID = c.SERVER
	where c.tasktype not like '%STOCK:SEQUENCE%'

	if @debug = 1
	begin

	SELECT 'debug_Summary_Join', LTRIM(RTRIM(@MaintPlanName))
		,LTRIM(RTRIM(b.SubPlanName))
		,LTRIM(RTRIM(c.server))
		,LTRIM(RTRIM(c.TaskName))
		,LTRIM(RTRIM(c.TaskType))
		,LTRIM(RTRIM(c.TaskEnabled))
		,LTRIM(RTRIM(c.DatabaseSelectionType))
		,LTRIM(RTRIM(c.IgnoreDatabaseState))
		,LTRIM(RTRIM(c.TaskOptions))
	FROM dbo.#SUBPLANS2 b
	LEFT JOIN [#MaintTask1] c ON c.SubPlanID = b.id
	--left JOIN #MaintPlanConnections2 d ON d.ConnectionID = c.SERVER

	select * from #MaintPlansReport
	end

	SET @MaintID = @MaintID + 1
END

/*	
Select * from #SUBPLANS1
Select * from #SUBPLANS2
Select * from #MaintTask1
Select * from #MaintPlanConnections1
Select * from #MaintPlanConnections2
*/
TRUNCATE TABLE #MaintPlans

SELECT *
FROM #MaintPlansReport
ORDER BY 1
	,2

TRUNCATE TABLE #MaintPlansReport
GO

DROP TABLE #SUBPLANS1

DROP TABLE #SUBPLANS2

DROP TABLE #MaintTask1

DROP TABLE #MaintPlans

DROP TABLE #MaintPlansReport

DROP TABLE #MaintPlanConnections1

DROP TABLE #MaintPlanConnections2
GO

