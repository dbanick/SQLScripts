#Declare SSRS URI
$sourceRsUri = 'http://sco-dev-db04/ReportServer'

#Declare Proxy so we dont need to connect with every command
$proxy = New-RsWebServiceProxy -ReportServerUri $sourceRsUri

#Output ALL Catalog items to file system
Write-RsFolderContent -Proxy $proxy -RsFolder /Admissions -Path 'F:\ssrs_prod\Admissions' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /AOD -Path 'F:\ssrs_prod\AOD' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Attorney Portal" -Path 'F:\ssrs_prod\Attorney Portal' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Attorney Services" -Path 'F:\ssrs_prod\Attorney Services' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Board of Commission on Grievance and Discipline" -Path 'F:\ssrs_prod\Board of Commission on Grievance and Discipline' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Boards and Commissions" -Path 'F:\ssrs_prod\Boards and Commissions' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /CDMS -Path 'F:\ssrs_prod\CDMS' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Civil Justice Grant" -Path 'F:\ssrs_prod\Civil Justice Grant' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /CLE -Path 'F:\ssrs_prod\CLE' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /CLESponsorPortal -Path 'F:\ssrs_prod\CLESponsorPortal' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Client Security Fund" -Path 'F:\ssrs_prod\Client Security Fund' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Continuing Legal Education" -Path 'F:\ssrs_prod\Continuing Legal Education' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Data Sources" -Path 'F:\ssrs_prod\Data Sources' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /eStats -Path 'F:\ssrs_prod\eStats' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /IGOR -Path 'F:\ssrs_prod\IGOR' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/JASPAY Reports" -Path 'F:\ssrs_prod\JASPAY Reports' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /JCIP -Path 'F:\ssrs_prod\JCIP' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Judicial and Court Services" -Path 'F:\ssrs_prod\Judicial and Court Services' -Recurse -Verbose
#Mayor's Court had to be modified to Mayors Court for upload purpose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Mayors Court" -Path 'F:\ssrs_prod\Mayors Court' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /Mediation -Path 'F:\ssrs_prod\Mediation' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Office of the Reporter" -Path 'F:\ssrs_prod\Office of the Reporter' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /PHV -Path 'F:\ssrs_prod\PHV' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder /TechnologyGrant -Path 'F:\ssrs_prod\TechnologyGrant' -Recurse -Verbose
Write-RsFolderContent -Proxy $proxy -RsFolder "/Vote Tracking" -Path 'F:\ssrs_prod\Vote Tracking' -Recurse -Verbose

