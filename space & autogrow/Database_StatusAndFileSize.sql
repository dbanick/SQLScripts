/***************************************************************************************************
Create Date:			2021-02-22
Author:					MSSQL Team
Description:			This query is used for reporting, trending and triggering purposes for MSSQL servers where Database Status and File Sizes
						will be monitored. Please see final output and notes for what columns will be used for these purposes.
Affected Zabbix Checks: [Database_State]
						[Database_Read_Only]
						[Database_Auto_Close]
						[Database_Auto_Shrink]
Parameter(s):			N/A
Prerequisites:			N/A
							
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
***************************************************************************************************/


/* Output which needs to be sent to Zabbix. 
		
	TRIGGER: Indicates the column is used for Zabbix triggering an alert
	TRENDING: Indicates the column is used for Zabbix data trending
	REPORTING: Indicates the column is used to report into Zabbix
	MAPPING: Indicates this column is used for mapping other Zabbix checks
	VALUES: Indicates we need to proivde the Zabbix Dev team the string values for the column results
*/

SET NOCOUNT OFF

DECLARE @command1 VARCHAR(4000)
DECLARE @command2 VARCHAR(1000)
DECLARE @dbID INT
DECLARE @maxID INT
DECLARE @vlfs INT  

DECLARE @MajorVersion TINYINT  
SET @MajorVersion = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(MAX)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(MAX)))-1) 
 
CREATE TABLE #db
(
	[Database_ID] INT,
	[Database_Name] VARCHAR(128)
)
CREATE TABLE #dbccloginfo   
(  
	[fileid] SMALLINT,  
	[file_size] BIGINT,  
	[start_offset] BIGINT,  
	[fseqno] INT,  
	[status] TINYINT,  
	[parity] TINYINT,  
	[create_lsn] NUMERIC(25,0)  
)
CREATE TABLE #dbccloginfo2012   
(  
    [RecoveryUnitId] INT, 
    [fileid] SMALLINT,  
    [file_size] BIGINT,  
    [start_offset] BIGINT,  
    [fseqno] INT,  
    [status] TINYINT,  
    [parity] TINYINT,  
    [create_lsn] NUMERIC(25,0)  
)  
CREATE TABLE #vlfcounts
(
	[database_id] INT,
	[fileid] SMALLINT,
    [vlfcount] INT
)  
CREATE TABLE #naviOutput
(
	[Database_ID] INT,
	[Database_Name] VARCHAR(128),
	[FG_Name] VARCHAR(128),
	[File_Name] VARCHAR(128),
	[File_ID] INT,
	[File_Type] INT,
	[Physical_File_Name] VARCHAR(260),
	[Total_Size_in_MB] FLOAT,
	[Available_Space_in_MB] FLOAT,
	[Used_Space_in_MB] FLOAT,
	[Percent_Free_Size] FLOAT,
	[Percent_Used_Size] FLOAT,
	[Max_Size] INT,
	[Percent_Free_Max_Size] FLOAT,
	[Percent_Used_Max_Size] FLOAT,
	[Autogrowth] INT,
	[Is_Percent_Autogrowth] BIT
);

INSERT INTO #db
SELECT [database_id], [name]
FROM master.sys.databases WHERE [state] = 0 AND [source_database_id] IS NULL

SELECT @dbID = MIN([Database_ID]), @maxID = MAX([Database_ID]) FROM #db
--error handling/trycatch; pull from master_files except the size data (check 2k8 master_files)
--can we return all this file data in PS

WHILE (@dbID <= @maxID and exists (select database_id from #db where database_id = @dbID))
BEGIN

	SELECT @command1 = 'USE ' + QUOTENAME([Database_Name]) + '; 
		SELECT
		db_id() as [Database_ID],
		db_name() AS [Database_Name],
		COALESCE(fg.[name], ''LOG'') as [FG_Name],
		f.[name] as [File_Name],
		f.[file_id] as [File_ID],
		f.[type] as [File_Type],
		f.[physical_name] AS [Physical_File_Name], 
		f.[size]/128.0 AS [Total_Size_in_MB],
		f.[size]/128.0 - CAST(FILEPROPERTY(f.[name], ''SpaceUsed'') AS int)/128.0 AS [Available_Space_in_MB], 
		CAST(FILEPROPERTY(f.[name], ''SpaceUsed'') AS int)/128.0 AS [Used_Space_in_MB],
		ROUND((size/128.0 - CAST(FILEPROPERTY(f.[name], ''SpaceUsed'') AS int)/128.0) * 100.0 / (f.[size]/128.0), 1) AS [Percent_Free_Size], 
		ROUND((CAST(FILEPROPERTY(f.[name], ''SpaceUsed'') AS int)/128.0) * 100.0 / (f.[size]/128.0), 1) AS [Percent_Used_Size], 
		CASE f.[Max_Size]
			WHEN 0 THEN ''0''
			WHEN -1 THEN ''-1''
			ELSE CAST(f.Max_Size / 128 as varchar(50))
		END as [Max_Size],
		CASE
			WHEN f.[max_size] = 0 THEN ''-1.0''
			WHEN f.[max_size] = -1 THEN ''-1.0''
			ELSE ROUND(((f.[max_size]/128.0 - (CAST(FILEPROPERTY(f.[name], ''SpaceUsed'') AS int)/128.0))/(f.[max_size]/128.0))*100,2)
		END as [Percent_Free_Max_Size], 
		CASE
			WHEN f.[max_size] = 0 THEN ''-1.0''
			WHEN f.[max_size] = -1 THEN ''-1.0''
			ELSE ROUND(((CAST(FILEPROPERTY(f.[name], ''SpaceUsed'') AS int)/128.0)/(f.[max_size]/128.0))*100,2)
		END as [Percent_Used_Max_Size],	 
		CASE f.[is_percent_growth]
			WHEN 0 THEN (f.[growth] / 128) 
			ELSE f.[growth]
		END as [Autogrowth], 
		f.[is_percent_growth]
	FROM sys.database_files f with (nolock) 
	LEFT JOIN sys.filegroups fg with (nolock) 
			ON f.data_space_id = fg.data_space_id
	' FROM #db WHERE [Database_ID] = @dbid

	SELECT @command2 = 'dbcc loginfo (' + QUOTENAME([Database_Name]) + ') '  
		FROM #db WHERE [Database_ID] = @dbid
  
	if @MajorVersion < 11 -- pre-SQL2012 
	BEGIN
		TRUNCATE TABLE #dbccloginfo
		INSERT INTO #dbccloginfo 
		EXEC (@command2) 

		INSERT INTO #vlfcounts
		SELECT @dbID, [fileid], count(1)
		FROM #dbccloginfo
		GROUP BY [fileid]
	END
	ELSE
	BEGIN
		TRUNCATE TABLE #dbccloginfo2012
		INSERT INTO #dbccloginfo2012  
		EXEC (@command2) 

		INSERT INTO #vlfcounts
		SELECT @dbID, [fileid], count(1)
		FROM #dbccloginfo2012
		GROUP BY [fileid]
	END

	INSERT INTO #naviOutput
	EXEC (@command1)
	--SELECT (@command1)

	SET @dbID += 1
END




SELECT 
	[Server_Name] = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(128)), /* Server Name: REPORTING */
	[Database_Name] = d.[name],			/* Database Name: REPORTING */
	CASE 
		WHEN d.[is_in_standby] = 1 AND d.[state] = 6
		THEN 0
		ELSE d.[state]
	END AS [Database_State], /* Database state: TRIGGER 
		0 = ONLINE
		1 = RESTORING
		2 = RECOVERING
		3 = RECOVERY_PENDING
		4 = SUSPECT
		5 = Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.
		6 = OFFLINE
		7 = DEFUNCT
		*/
	--[Database_State_Description] = [state_desc],	/* Database state_desc: REPORTING */
	[Database_Read_Only] = d.[is_read_only], /* Database Read Only state: REPORTING 		
		1 = Database is READ_ONLY
		0 = Database is READ_WRITE
		*/
	[Database_Auto_Close] = d.[is_auto_close_on], /* Database Auto Close state: TRIGGER 
		1 = AUTO_CLOSE is ON
		0 = AUTO_CLOSE is OFF
		*/
	[Database_Auto_Shrink] = d.[is_auto_shrink_on], /* Database Auto Shrink state: REPORTING 
		1 = AUTO_SHRINK is ON
		0 = AUTO_SHRINK is OFF
		*/
	[Database_Compatibility_Level] = d.[compatibility_level], /* Database compatibility level: REPORTING 
		Integer corresponding to the version of SQL Server for which behavior is compatible:
		Value	Applies to
		70	SQL Server 7.0 through SQL Server 2008
		80	SQL Server 2000 (8.x) through SQL Server 2008 R2
		90	SQL Server 2008 through SQL Server 2012 (11.x)
		100	SQL Server (Starting with SQL Server 2008) and Azure SQL Database
		110	SQL Server (Starting with SQL Server 2012 (11.x)) and Azure SQL Database
		120	SQL Server (Starting with SQL Server 2014 (12.x)) and Azure SQL Database
		130	SQL Server (Starting with SQL Server 2016 (13.x)) and Azure SQL Database
		140	SQL Server (Starting with SQL Server 2017 (14.x)) and Azure SQL Database
		150	SQL Server (Starting with SQL Server 2019 (15.x)) and Azure SQL Database
		*/
	[Recovery_Model] = d.[recovery_model],	/* Database Recovery Model: REPORTING 
		1 = FULL
		2 = BULK_LOGGED
		3 = SIMPLE
		*/
	[User_Access] = d.[user_access],		/* User Access Description: REPORTING 
		0 = MULTI_USER specified
		1 = SINGLE_USER specified
		2 = RESTRICTED_USER specified
		*/
	[Log_Reuse_Wait] = d.[log_reuse_wait], /* Log Reuse Wait Type: REPORTING  
		0 = Nothing
		1 = Checkpoint (When a database has a memory-optimized data filegroup, you should expect to see the log_reuse_wait column indicate checkpoint or xtp_checkpoint) 1
		2 = Log Backup 1
		3 = Active backup or restore 1
		4 = Active transaction 1
		5 = Database mirroring 1
		6 = Replication 1
		7 = Database snapshot creation 1
		8 = Log scan
		9 = An Always On Availability Groups secondary replica is applying transaction log records of this database to a corresponding secondary database. 2
		9 = Other (Transient) 3
		10 = For internal use only 2
		11 = For internal use only 2
		12 = For internal use only 2
		13 = Oldest page 2
		14 = Other 2
		16 = XTP_CHECKPOINT (When a database has a memory-optimized data filegroup, you should expect to see the log_reuse_wait column indicate checkpoint or xtp_checkpoint) 4

		1 Applies to: SQL Server (starting with SQL Server 2008)
		2 Applies to: SQL Server (starting with SQL Server 2012 (11.x))
		3 Applies to: SQL Server (up to, and including SQL Server 2008 R2)
		4 Applies to: SQL Server (starting with SQL Server 2014 (12.x))
		*/
	[VLF_Count] = COALESCE(v.[vlfcount], -1),	/* Total Number of VLF's for database: REPORTING, TRIGGER, TRENDING  
		-1 = No VLF's (data file) or cannot read database
		*/
	[DB_Owner] = COALESCE(suser_sname(d.[owner_sid]), 'N/A'),		/* Database Owner: REPORTING  */
	[Is_Trustworthy_On] = d.[is_trustworthy_on],		/* Trustworthy Status: REPORTING  
		1 = Database has been marked trustworthy
		0 = Database has not been marked trustworthy
		*/
	[Is_DB_Chaining_On] = d.[is_db_Chaining_on],		/* Database Chaining Status: REPORTING  
		1 = Cross-database ownership chaining is ON
		0 = Cross-database ownership chaining is OFF
		*/
	[Is_Encrypted] = d.[is_encrypted], /* Encryption Status: REPORTING 
		1 = Encrypted
		0 = Not Encrypted
		*/
	[Collation_Name] = COALESCE(d.[collation_name], 'N/A'),	/* Database Collation: REPORTING  */
	[Snapshot_Isolation_State] = d.[snapshot_isolation_state],	/* Snapshot Isolation: REPORTING  
		0 = Snapshot isolation state is OFF (default). Snapshot isolation is disallowed.
		1 = Snapshot isolation state ON. Snapshot isolation is allowed.
		2 = Snapshot isolation state is in transition to OFF state. 
		3 = Snapshot isolation state is in transition to ON state. 
		*/
	[Is_Read_Committed_Snapshot_On] = d.[is_read_committed_snapshot_on],	/* Read Committed Snapshot Status: REPORTING  
		1 = READ_COMMITTED_SNAPSHOT option is ON. 
		0 = READ_COMMITTED_SNAPSHOT option is OFF (default). 
		*/
	[Page_Verify_Option] = d.[page_verify_option],	/* Page Verify Options: REPORTING  
		0 = NONE
		1 = TORN_PAGE_DETECTION
		2 = CHECKSUM
		*/
	[is_broker_enabled] = d.[is_broker_enabled],	/* Service Broker Status: REPORTING  
		1 = The broker in this database is currently sending and receiving messages.
		0 = All sent messages will stay on the transmission queue and received messages will not be put on queues in this database.
		*/
	[is_cdc_enabled] = d.[is_cdc_enabled],		/* CDC status: REPORTING  
		0 = Database is not enabled for change data capture
		1 = Database is enabled for change data capture
		*/
	[Create_Date] = d.[create_date], /* Date the database was created or renamed: REPORTING */
	[File_Name] = COALESCE(mf.[name], 'N/A'), /* File Name: REPORTING */
	[File_ID] = COALESCE(mf.[File_ID], -1), /* File ID: REPORTING 
		-1 = Replaces NULL value / could not be determined
.		Any other number indicates actual File ID
		*/
	[FileGroup_Name] = COALESCE(n.[FG_Name], 'N/A'), /* FileGroup Name: REPORTING */
	[File_Type] = COALESCE(COALESCE(n.[File_Type],mf.[type]), -1), /* File Type: REPORTING 
		-1 = Replaces NULL value / could not be determined
		0 = Rows
		1 = Log
		2 = FILESTREAM
		3 = Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.
		4 = Full-text
		*/
	[Physical_File_Name] = COALESCE(COALESCE(n.[Physical_File_Name],mf.[physical_name]), 'N/A'), /* Physical file name: REPORTING */
	[Total_Size_in_MB] = COALESCE(n.[Total_Size_in_MB], -1), /* Calculate the total space in use (in MB) within the file: REPORTING, TRENDING 
		-1 = Replaces NULL value / could not be determined
		*/
	[Available_Space_in_MB] = COALESCE(n.[Available_Space_in_MB], -1), /* Calculates the current available space left in the file (In MB): REPORTING, TRENDING 
		-1 = Replaces NULL value / could not be determined
		*/
	[Used_Space_in_MB] = COALESCE(n.[Used_Space_in_MB], -1), /* Calculates percentage of current available space in file based on existing file size minus allocated space: REPORTING, TRENDING 
		-1 = Replaces NULL value / could not be determined
		*/
	[Max_Size] = COALESCE(n.[Max_Size], -2), /* Calculates remaining file space percentage based on autogrowth being turned ofmf. Equation is (max_file_size - (current_file_max_alloc - current_file_alloc))/max_file_size): REPORTING 
		0 = No growth is allowed.
		-1 = File will grow until the disk is full.
		-2 = Replaces NULL value / could not be determined
		268435456 = Log file will grow to a maximum size of 2 TB
		Any other number reflects the actual max size
		*/
	[Is_Percent_Autogrowth] = COALESCE(n.[Is_Percent_Autogrowth], -1), /* Whether Autogrow is using a percentage or a static increment: REPORTING 
		-1 = Replaces NULL value / could not be determined
		0 = percentage
		1 = static MB increment
		*/
	[Autogrowth] = COALESCE(n.[Autogrowth], -1), /* Whether Autogrow is using a percentage or a static increment: REPORTING 
		-1 = Replaces NULL value / could not be determined
		0 = File is fixed size and will not grow.
		>0 = File will grow automatically.
		If is_percent_growth = 0, growth increment is in units of 8-KB pages, rounded to the nearest 64 KB.
		If is_percent_growth = 1, growth increment is expressed as a whole number percentage.
		*/
	CASE WHEN vfs.[num_of_reads] = 0
				THEN 0 
			WHEN vfs.[num_of_reads] IS NULL 
				THEN -1
			ELSE (vfs.[io_stall_read_ms] / vfs.[num_of_reads]) END AS [ReadLatency], /* Read Latency of the file: REPORTING, TRENDING, DELTA */
    CASE WHEN vfs.[num_of_writes] = 0
				THEN 0  
			WHEN vfs.[num_of_writes] IS NULL 
				THEN -1
			ELSE (vfs.[io_stall_write_ms] / vfs.[num_of_writes]) END AS [WriteLatency], /* Write Latency of the File: REPORTING, TRENDING, DELTA */
    CASE WHEN (vfs.[num_of_reads] = 0 AND vfs.[num_of_writes] = 0)
				THEN 0 
			WHEN (vfs.[num_of_reads] IS NULL OR vfs.[num_of_writes] IS NULL)
				THEN -1
			ELSE (vfs.[io_stall] / (vfs.[num_of_reads] + vfs.[num_of_writes])) END AS [Latency], /* Total Read/Write Latency of the File: REPORTING, TRENDING, DELTA */
    CASE WHEN vfs.[num_of_reads] = 0
				THEN 0 			
			WHEN vfs.[num_of_reads] IS NULL 
				THEN -1
			ELSE (vfs.[num_of_bytes_read] / vfs.[num_of_reads]) END AS [AvgBPerRead], /* Average Bytes Per Read in File: REPORTING, TRENDING, DELTA */
    CASE WHEN vfs.[num_of_writes] = 0
				THEN 0 
			WHEN vfs.[num_of_reads] IS NULL 
				THEN -1
			ELSE (vfs.[num_of_bytes_written] / vfs.[num_of_writes]) END AS [AvgBPerWrite], /* Average Bytes Per Write in File: REPORTING, TRENDING, DELTA */
    CASE WHEN (vfs.[num_of_reads] = 0 AND vfs.[num_of_writes] = 0)
				THEN 0 
			WHEN (vfs.[num_of_reads] IS NULL OR vfs.[num_of_writes] IS NULL)
				THEN -1
			ELSE
                ((vfs.[num_of_bytes_read] + vfs.[num_of_bytes_written]) /
                (vfs.[num_of_reads] + vfs.[num_of_writes])) END AS [AvgBPerTransfer] /* Average Bytes Per Read/Write in File: REPORTING, TRENDING, DELTA */
FROM [master].[sys].[databases] d  with (nolock) 
LEFT JOIN [master].[sys].[master_files] mf  with (nolock) 
	ON mf.[database_id] = d.[database_id]
LEFT JOIN #naviOutput n
	ON n.[database_id] = mf.[database_id] 
	AND mf.[file_id] = n.[File_ID]
LEFT JOIN #vlfcounts v
	ON d.[database_id] = v.[database_id]
	AND mf.[file_id] = v.[fileid]
LEFT JOIN sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]
    ON [vfs].[database_id] = [mf].[database_id]
    AND [vfs].[file_id] = [mf].[file_id]

ORDER BY 2 ASC
GO
DROP TABLE #naviOutput, #db, #dbccloginfo, #dbccloginfo2012, #vlfcounts

