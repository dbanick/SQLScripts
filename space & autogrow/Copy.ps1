robocopy "D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup" \\uss-nas03\USS-SQL20\ *.bak /s

---------------------------------

param(
[string]$db='ClaimsBT',
[string[]]$srcdir= '\\ps-backup\databases\PS2\',
[string[]]$destdir = 'E:\dbRefresh\',
[string]$type='FULL'
)
cls
$db +="_$type"

$files = (Get-ChildItem $srcDir -filter "PS2_$db*.bak" | where-object {-not ($_.PSIsContainer)} | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-1)} );
$files|foreach($_){
    #$_.Name
    #$_.FullName
    $file = "$destdir$_"
    #$file
 
    if (!(Test-Path ($file))){
           write-host "does not exist : " $_.Fullname
           cp $_.Fullname ($file)
    }
    else { write-host "exists : " $file }
}