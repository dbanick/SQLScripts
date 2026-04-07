#This will cleanup files based on extension and age for specified folder

param(
[Int32]$days=7,
[string]$ext='.trn',
[string]$path='s3://asdf-prod-db-backup/Archives/dbbackuplogs_MAS500'
)

#$days = 3
#$ext = '.trn'
#$path = "s3://asdf-prod-db-backup/Archives/dbbackuplogs_MAS500"


#add a wildcharacter to the extension
$ext = "*$ext"

#get date, find cutoff based on retention
$now = Get-Date
$lastWrite = $now.AddDays(-$days).ToString('yyyy-MM-dd')
 
#debug
#$days
#$ext
#$folder
#$lastWrite

#find files in S3
$a = aws s3 ls $path/

#build array out of list
$ar = @()
for ($i=0; $i -lt $a.Count; $i++) {

#$ar += ,@($a[$i].Substring(0,10), $a[$i].substring(31))
$ar += @(
    [pscustomobject]@{Name=$a[$i].substring(31);date=$a[$i].Substring(0,10)}
)

}

#get files based on lastwrite, extension, and specified folder
$ar2 = $ar | Where {$_.Date -le "$lastWrite"} 
$ar2 = $ar2 | where {$_.Name -like "$ext"}
$files = $ar2.name

foreach ($file in $files) 
    {
    if ($file -ne $NULL)
        {
        write-host "Deleting File $file" -ForegroundColor "DarkRed"
        aws s3 rm $path/$file 
        }
    else
        {
        Write-Host "No more files to delete!" -foregroundcolor "Green"
        }
    }
