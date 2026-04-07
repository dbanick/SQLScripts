/***************************************************************************************************
Create Date:                    2021-07-14
Author:                         MSSQL Team
Description:                    This query is used for reporting, trending and triggering purposes for MSSQL servers where instance information
                                will be monitored. Please see final output and notes for what columns will be used for these purposes.

Affected Zabbix Checks:         

Parameter(s):

Prerequisites:
						
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2021-07-19          Scott Caldwell      Reviewed for style and coding practices
------------------- ------------------- ------------------------------------------------------------
2021-07-20          Ravinder pal Singh  Added startup trace flags
------------------- ------------------- ------------------------------------------------------------
2021-07-22          Ravinder pal Singh  Added SQL port and returned MSSQLSERVER for default instance
------------------- ------------------- ------------------------------------------------------------
2021-07-28          Ravinder pal Singh  Reading trace flags from registry for SQL 2008 and dmv from versions onwards
***************************************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* TCP port. Either Dynamic or static */
DECLARE @InstanceName nvarchar(50)
DECLARE @Portnumber VARCHAR(100)
DECLARE @RegKey_InstanceName nvarchar(500)
DECLARE @RegKey nvarchar(500), @RegKey_TF NVARCHAR(500), @Trace_Flags_Concat VARCHAR(500)

 
SET @InstanceName=CONVERT(nVARCHAR,isnull(SERVERPROPERTY('INSTANCENAME'),'MSSQLSERVER'))

--For SQL Server 2005 and up
if(SELECT Convert(varchar(1),(SERVERPROPERTY('ProductVersion'))))<>8
BEGIN
SET @RegKey_InstanceName='SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'

EXECUTE xp_regread
  @rootkey = 'HKEY_LOCAL_MACHINE',
  @key = @RegKey_InstanceName,
  @Portnumber_name = @InstanceName,
  @Portnumber = @Portnumber OUTPUT

SET @RegKey='SOFTWARE\Microsoft\Microsoft SQL Server\'+@Portnumber+'\MSSQLServer\SuperSocketNetLib\TCP\IPAll'

--For trace flags
SET @RegKey_TF = N'SOFTWARE\\Microsoft\\Microsoft SQL Server\\'+@Portnumber+'\\MSSQLServer\\Parameters'

EXECUTE xp_regread
  @rootkey = 'HKEY_LOCAL_MACHINE',
  @key = @RegKey,
  @Portnumber_name = 'TcpPort',
  @Portnumber = @Portnumber OUTPUT
 
--Select @@SERVERNAME as ServerName,@Portnumber as PortNumber
END

--IF SQL 2008(Not R2), read from registry
IF (SELECT CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(10))) LIKE '10.0.%'
BEGIN
-- Get all of the arguments / parameters when starting up the service.
DECLARE @SQLArgs TABLE (
    Value   VARCHAR(50),
    Data    VARCHAR(500),
    ArgNum  AS CONVERT(INTEGER, REPLACE(Value, 'SQLArg', '')));
 
INSERT INTO @SQLArgs
    EXECUTE master.sys.xp_instance_regenumvalues 'HKEY_LOCAL_MACHINE', @RegKey_TF;

SET @Trace_Flags_Concat = ISNULL((SELECT REPLACE(REPLACE(STUFF(REPLACE(REPLACE((SELECT '#!' + LTRIM(RTRIM(CAST([Data] AS VARCHAR(MAX)))) AS 'data()' FROM @SQLArgs WHERE CAST([Data] AS VARCHAR(MAX)) LIKE '-T%' FOR XML PATH('')),' #!',','),'&#x0',''), 1, 2, ''),'-T',''),'0;','')),0)
END
/* 
Final data which needs to be sent to Zabbix. 
		 
TRIGGER: Indicates the column is used for Zabbix triggering an alert
TRENDING: Indicates the column is used for Zabbix data trending
REPORTING: Indicates the column is used to report into Zabbix
MAPPING: Indicates this column is used for mapping other Zabbix checks
VALUES: Indicates we need to proivde the Zabbix Dev team the string values for the column results

NOTES:                  
COMMENT FORMAT:         Datatype | Column Type | Description
RESULTSET GRANULARITY:  1 row per SQL Server instance
*/

SELECT
	 [ServerName] = SERVERPROPERTY('ServerName') /* Both the Windows server and instance information associated with a specified instance of SQL Server. */
	,[PortNumber] = ISNULL(@Portnumber,0)
	,[StartupFlags] = CASE WHEN @Trace_Flags_Concat IS NOT NULL THEN @Trace_Flags_Concat
						   ELSE ISNULL((SELECT REPLACE(REPLACE(STUFF(REPLACE(REPLACE((SELECT '#!' + LTRIM(RTRIM(CAST(value_data  AS VARCHAR(MAX)))) AS 'data()' FROM sys.dm_server_registry WHERE CAST(value_data  AS VARCHAR(MAX)) LIKE '-T%' FOR XML PATH('')),' #!',','),'&#x0',''), 1, 2, ''),'-T',''),'0;','')),0)
					  END
	,[Edition] = ISNULL(SERVERPROPERTY('Edition'), 'N/A')
	,[ProductBuildType] = ISNULL(SERVERPROPERTY('ProductBuildType'),'N\A') /* Applies to: SQL Server 2012 (11.x) through current version in updates beginning in late 2015. */
	,[ProductLevel] = ISNULL(SERVERPROPERTY('ProductLevel'), 'N/A')
	,[ProductUpdateLevel] = ISNULL(SERVERPROPERTY('ProductUpdateLevel'), 'N/A') /* Applies to: SQL Server 2012 (11.x) through current version in updates beginning in late 2015. */
	,[ProductUpdateReference] = ISNULL(SERVERPROPERTY('ProductUpdateReference'), 'N/A') /* Applies to: SQL Server 2012 (11.x) through current version in updates beginning in late 2015. */
	,[ProductVersion] = ISNULL(SERVERPROPERTY('ProductVersion'), 'N/A')
	,[InstanceDefaultBackupPath] = ISNULL(SERVERPROPERTY('InstanceDefaultBackupPath'), 'N/A') /* Applies to: SQL Server 2019 (15.x) and later. */
	,[InstanceDefaultDataPath] = ISNULL(SERVERPROPERTY('InstanceDefaultDataPath'), 'N/A') /* Applies to: SQL Server 2012 (11.x) through current version in updates beginning in late 2015. */
	,[InstanceDefaultLogPath] = ISNULL(SERVERPROPERTY('InstanceDefaultLogPath'), 'N/A') /* Applies to: SQL Server 2012 (11.x) through current version in updates beginning in late 2015. */
	,[Collation] = ISNULL(SERVERPROPERTY('Collation'), 'N/A')
	,[ResourceVersion] = ISNULL(SERVERPROPERTY('ResourceVersion'), 'N/A')
	,[ResourceLastUpdateDateTime] = ISNULL(SERVERPROPERTY('ResourceLastUpdateDateTime'),'1900-01-01')
	,[IsHadrEnabled] = ISNULL(SERVERPROPERTY('IsHadrEnabled'), 0) /* Applies to: SQL Server 2012 (11.x) and later. */
	,[IsClustered] = ISNULL(SERVERPROPERTY('IsClustered'), 0)
	,[IsReplicated] = ISNULL((
				SELECT TOP 1 ReplicationCheck = 1
				FROM sys.databases
				WHERE is_published = 1
					OR is_subscribed = 1
					OR is_merge_published = 1
					OR is_distributor = 1
				), 0)
	,[IsLogShipped] = ISNULL((
				SELECT TOP 1 LogShippingCheck = 1
				FROM sys.databases
				WHERE name IN (
						SELECT primary_database
						FROM msdb..log_shipping_primary_databases
						)
					OR name IN (
						SELECT secondary_database
						FROM msdb..log_shipping_secondary_databases
						)
				), 0) 
	,[IsMirrored] = ISNULL((
				SELECT TOP 1 MirroringCheck = 1
				FROM sys.databases AS d
				INNER JOIN sys.database_mirroring AS dm ON d.database_id = dm.database_id
				WHERE dm.mirroring_state IS NOT NULL
				), 0)
	,[IsFullTextInstalled] = ISNULL(SERVERPROPERTY('IsFullTextInstalled'), 0)
	,[IsIntegratedSecurityOnly] = ISNULL(SERVERPROPERTY('IsIntegratedSecurityOnly'), 0)
	,[FilestreamConfiguredLevel] = ISNULL(SERVERPROPERTY('FilestreamConfiguredLevel'),0)
	,[FilestreamShareName] = ISNULL(SERVERPROPERTY('FilestreamShareName'),0)
	,[LocalServerTime] = GETDATE()
	,[UTCTime] =  GETUTCDATE()