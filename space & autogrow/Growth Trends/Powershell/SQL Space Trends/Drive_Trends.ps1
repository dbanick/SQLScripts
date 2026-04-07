cls

$directoryPath = Split-Path $MyInvocation.MyCommand.Path
Write-Host "Working out of directory $directoryPath\"
cd $directoryPath



##Qualify the function used
. .\functions\invoke-sqlcmd2.ps1
. .\functions\Write-DataTable.ps1

$srvlist = @(get-content ".\ServerList.txt")

foreach ($instance in $srvlist)
{
$dt = Invoke-Sqlcmd2 -ServerInstance $instance -Database master "use master

DECLARE @version numeric(4,2), @servicePak int, @ExecCmd varchar(600)

SET @version = (SELECT CAST(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') as varchar(50)), 1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') as varchar(50)))+1 ) as numeric(4,2)))
set @servicePak = (select CONVERT(int,CASE WHEN ISNUMERIC(RIGHT(CAST(serverproperty('ProductLevel') as varchar(3)),1)) = 1 THEN RIGHT(CAST(serverproperty('ProductLevel') as varchar(3)),1) ELSE 0 END))

CREATE TABLE #DriveSpace
	(
	Servername varchar(300),
	Drive varchar(300),
	TotalSpaceInGB varchar(20) DEFAULT 'N/A' NOT NULL,
	FreeSpaceInGB numeric(20,2) NOT NULL,
	RunDate datetime DEFAULT GETDATE()
	)

IF @version >= 11 OR (@version = 10.5 AND RIGHT(@servicePak,1) >= 1)
	BEGIN
		SET @ExecCmd = '
SELECT DISTINCT
	@@servername as servername,
	b.volume_mount_point as Volume, 
	CAST(ROUND(CAST(b.total_bytes as numeric(20,2))/1024.00/1024.00/1024.00,2) AS numeric(20,2)) as TotalSpaceInGB, 
	CAST(ROUND(CAST(b.available_bytes as numeric(20,2))/1024.00/1024.00/1024.00,2) AS numeric(20,2)) as FreeSpaceInGB,
	GETDATE() as RunDate
FROM sys.master_files a
OUTER APPLY [sys].[dm_os_volume_stats](a.database_id,a.file_id) b'
		
		INSERT INTO #DriveSpace 
			(servername,drive,TotalSpaceInGB,FreeSpaceInGB,rundate)
			EXEC(@ExecCmd)
	END

 ELSE
	BEGIN
		INSERT INTO #DriveSpace 
			(Drive,FreeSpaceInGB)
			EXEC xp_fixeddrives
		
		Update #Drivespace
			set Servername = @@servername

		UPDATE #DriveSpace
			SET FreeSpaceInGB = CAST(ROUND((FreeSpaceInGB/1024.00),2) as numeric(20,2))
		
		UPDATE #DriveSpace
			set rundate = GETDATE()

		UPDATE #DriveSpace
			set Drive = Drive + ':\'
	END

SELECT * FROM #DriveSpace ORDER BY Drive

DROP TABLE #DriveSpace
"

Write-DataTable -ServerInstance "." –Database Master –TableName RDX_Drive_Growth_Stats -Data $dt
}