$ServerName = get-content env:computername
$Path = "C:\Temp\" + $ServerName + "_volumeinfo.csv"
Get-WmiObject win32_logicaldisk -Filter "DriveType=3" | select-object {$ServerName}, DeviceID,VolumeName,@{Name=”Free Space (GB)”;Expression={[math]::round($_.FreeSpace / 1GB,0)}},@{Name=”Size in GB”;Expression={[math]::round($_.Size /1GB,0)}} | export-csv -Path $Path
