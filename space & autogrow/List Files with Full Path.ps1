get-childitem -Path G:\Backups\model -recurse | Sort CreationTime | % {
     Write-Host $_.FullName
}