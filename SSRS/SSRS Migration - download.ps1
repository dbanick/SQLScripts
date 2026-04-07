#https://github.com/Microsoft/ReportingServicesTools

#------------------------------------------------------
#Prerequisites
#Install-Module -Name ReportingServicesTools
#------------------------------------------------------

#Lets get security on all folders in a single instance
#------------------------------------------------------
#Declare SSRS URI
$sourceRsUri = 'http://sco-prod-db04/ReportServer'

#Declare Proxy so we dont need to connect with every command
$proxy = New-RsWebServiceProxy -ReportServerUri $sourceRsUri

#Output ALL Catalog items to file system
Out-RsFolderContent -Proxy $proxy -RsFolder / -Destination 'F:\temp' -Recurse 
