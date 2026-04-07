cd C:
#----enter path---#
$targetpath = "G:\Backups\"
#----enter the days---#
$days = 7
#----extension of the file to delete---#
$Extension = "*bak"
$Now = Get-Date
$LastWrite = $Now.AddDays(-$days)
#----- get files based on lastwrite filter in the specified folder ---#
$Files = Get-Childitem $targetpath -Include $Extension -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}
foreach ($File in $Files)
    {
    if ($File -ne $NULL)
        {      
	        Remove-Item $File.FullName | out-null
        }
    }