$directoryPath = "C:\RDX\Powershell\SQL Space Trends\"
cd $directoryPath


##Qualify the function used
. .\functions\invoke-sqlcmd2.ps1
. .\functions\Write-DataTable.ps1
. .\functions\Out-DataTable.ps1
     
$srvlist = "PS2", "EDIDB", "MASSQL"
$unit = "GB"
$measure = "1$unit"
$wmiQuery = "
SELECT SystemName, Name, DriveType, FileSystem, FreeSpace, Capacity, Label
FROM Win32_Volume WHERE DriveType = 3
"

foreach ($instance in $srvlist)
{
$dt = Get-WmiObject -ComputerName $instance -Query $wmiQuery |
Select-Object SystemName, Name, @{Label="TotalSpaceIn$unit"; Expression={"{0:n2}" -f ($_.Capacity/$measure)}}, @{Label="FreeSpaceIn$unit"; Expression={"{0:n2}" -f ($_.FreeSpace/$measure)}} |
Where-Object {$_.Name -NotLike '\\?\*'} |
Sort-Object Name | Out-DataTable

Write-DataTable -ServerInstance "PS2" –Database Master -TableName RDX_Drive_Growth_Stats -data $dt
}