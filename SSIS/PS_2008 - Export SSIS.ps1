#set server name
Param($SQLInstance = "BVLPROD4")

#####Add all the SQL goodies (including Invoke-Sqlcmd)#####
add-pssnapin sqlserverprovidersnapin100 -ErrorAction SilentlyContinue
add-pssnapin sqlservercmdletsnapin100 -ErrorAction SilentlyContinue
cls 

$Packages =  Invoke-Sqlcmd -MaxCharLength 10000000 -ServerInstance $SQLInstance -Query "
           SELECT   distinct p.name,CAST(CAST(packagedata AS VARBINARY(MAX)) AS VARCHAR(MAX)) as pkg
       FROM msdb..sysssispackages  p   
       
       
       "
Foreach ($pkg in $Packages)
{
    $pkgName = $Pkg.name
    $folderPath = $Pkg.folderpath
#set path for where to export ssis packages
    $fullfolderPath = "D:\SSIS"
    if(!(test-path -path $fullfolderPath))
    {
        mkdir $fullfolderPath | Out-Null
    }
    $pkg.pkg | Out-File -Force -encoding ascii -FilePath "$fullfolderPath\$pkgName.dtsx"
}