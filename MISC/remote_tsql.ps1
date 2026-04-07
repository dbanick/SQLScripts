# Powershell script to connect to a list of servers and run a SQL script
# USAGE: powershell.exe myscript.ps1 -stores "C:\storelist.txt" -tsql "C:\script.sql" -csv "C:\VFSCount.csv"

# Default parameters unless specified by command-line args
param (
	[string]$stores = "C:\Powershell\storelist_and_central.txt",
	[string]$tsql = "c:\Powershell\DD cleanup\DD_Cleanup_retention.sql",
	[string]$csv = "C:\Powershell\FreeSpaceMB.csv"
)

Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100



[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
cls
$Target= @()
	ForEach ($instance in Get-Content $stores){
 
		$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $instance
		Write-Host "$instance"
        
		# Run SQL command
		invoke-sqlcmd -inputfile $tsql -serverinstance $instance 
 
		 
	}


