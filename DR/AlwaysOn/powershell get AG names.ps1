#determine which node is primary or secondary in AG

[System.Reflection.Assembly]::LoadWithPartialName(“Microsoft.SqlServer.Smo”) |  Out-Null

$Server = hostname

$SqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server(“$server”)
  

$ags = $SqlServer.AvailabilityGroups
foreach ($ag in $ags.name){

$primary = $SqlServer.AvailabilityGroups[“$ag”].primaryReplicaServername
$reps = $SqlServer.AvailabilityGroups[“$ag”].AvailabilityReplicas #replicas
$secondarys =  $reps | where {$_.role -eq 'Secondary'}
 
 write-host "AG name is $ag"
 write-host "primary is $primary"
 write-host "secondary's are $secondarys"
 }