#pretty sure this is for SQL 2005 or 2008; exports SSIS packages
#this will update the connection from the original server name, replacing it with BHPSQLAPPSWV02 server


Param($SQLInstance = "SQLSRV00")

#####Add all the SQL goodies (including Invoke-Sqlcmd)#####
add-pssnapin sqlserverprovidersnapin100 -ErrorAction SilentlyContinue
add-pssnapin sqlservercmdletsnapin100 -ErrorAction SilentlyContinue
cls 

$Packages =  Invoke-Sqlcmd -MaxCharLength 10000000 -ServerInstance $SQLInstance -Query "
           WITH cte AS (

           SELECT    cast(foldername as varchar(max)) as folderpath, folderid
           FROM    msdb..sysdtspackagefolders90
           
           UNION    ALL
           SELECT    cast(c.folderpath + '\' + f.foldername  as varchar(max)), f.folderid
           FROM    msdb..sysdtspackagefolders90  f
           INNER    JOIN cte c        ON    c.folderid = f.parentfolderid
       )
       SELECT   distinct REPLACE(c.folderpath, 'sqlsrv00', 'BHPSQLAPPSWV02') as folderpath,
       REPLACE(p.name, 'sqlsrv00', 'BHPSQLAPPSWV02') as name,
       REPLACE(CAST(CAST(packagedata AS VARBINARY(MAX)) AS VARCHAR(MAX)), 'sqlsrv00', 'BHPSQLAPPSWV02') as pkg
       FROM    cte c
       RIGHT    JOIN msdb..sysdtspackages90  p    ON    c.folderid = p.folderid
       WHERE    c.folderpath NOT LIKE 'Data Collector%'
       and c.folderpath not in ('Copy Database Wizard Packages', 'DTS Packages\Copy Database Wizard Packages', 'SQLSRV00\DTS Packages\Copy Database Wizard Packages')
       
       
       
       "
Foreach ($pkg in $Packages)
{
    $pkgName = $Pkg.name
    $folderPath = $Pkg.folderpath
    $fullfolderPath = "X:\ssis_new\$folderPath\"
    if(!(test-path -path $fullfolderPath))
    {
        mkdir $fullfolderPath | Out-Null
    }
    $pkg.pkg | Out-File -Force -encoding ascii -FilePath "$fullfolderPath\$pkgName.dtsx"
}