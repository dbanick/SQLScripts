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
$dt = Invoke-Sqlcmd2 -ServerInstance $instance -Database master "CREATE TABLE #dbStats(
[Servername] [sysname] NULL,
[RunDate] [datetime] NULL,
[DBName] [sysname] NULL,
[Name] [sysname] NULL,
[FileName] [nchar](520) NULL,
[TotalSize] [float] NULL,
[UsedSpace] [float] NULL,
[FreeSpace] [float] NULL,
[FileID] [int] NULL)

EXEC sp_msforeachdb 'USE [?]

DECLARE @PageSize float
SELECT @PageSize = v.low /1024.0 FROM master.dbo.spt_values v WHERE v.number = 1 AND v.type = ''E''

INSERT INTO #dbStats
SELECT @@servername AS ServerName,
GETDATE() AS RunDate,
''?'' AS DBName,
RTRIM(s.name) AS [Name],
RTRIM(s.filename) AS [FileName],
(s.size * @PageSize) AS [TotalSize],
CAST(FILEPROPERTY(s.name, ''SpaceUsed'') AS float)* CONVERT(float, 8) AS [UsedSpace],
(s.size * @PageSize) - CAST(FILEPROPERTY(s.name, ''SpaceUsed'') AS float) * CONVERT(float, 8) AS [FreeSpace],
CAST(s.fileid AS int) AS [ID]
FROM sysfiles AS s'

SELECT * FROM #dbStats"
Write-DataTable -ServerInstance "." –Database Master –TableName RDX_DB_Growth_Stats -Data $dt
}