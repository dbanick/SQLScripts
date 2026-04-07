Function Get-PowerPlan {
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String[]]$ServerNames = $env:COMPUTERNAME
    )

    process {
        foreach ($ServerName in $ServerNames) {
            try {
                Get-WmiObject -ComputerName $ServerName -Class Win32_PowerPlan -Namespace "root\cimv2\power" |
                    Where-Object {$_.IsActive -eq $true} |
                    Select-Object @{Name = "ServerName"; Expression = {$ServerName}}, @{Name = "PowerPlan"; Expression = {$_.ElementName}}
            }
            
            catch {
                Write-Error $_.Exception
            }
        }
    }
}

# Uncomment this block if you want a list of servers in a text file
 Get-Content -Path "d:\temp\ServerList.txt" | Get-PowerPlan | Export-Csv -Path "D:\Temp\OutputPowerPlan.csv" -NoTypeInformation


# Uncomment this block if you want a hard coded list
<#
$ServerNames = "ALWAYSON1", "ALWAYSON2", "STRINGERHOST", "STRINGERDC", "STRINGERSTOR1", "FCI1", "FCI2"
$ServerNames |   Get-PowerPlan |  Where-Object {$_.PowerPlan -ne "High performance"}
#>


# Uncomment this block if you want a list of servers in a Database table as below.
<#
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

$SqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server("YourSqlServer")
$SqlServer.Databases["TestDB"].ExecuteWithResults("select name from dbo.server_list;").Tables[0] |
    Select-Object -ExpandProperty Name | Get-PowerPlan
#>