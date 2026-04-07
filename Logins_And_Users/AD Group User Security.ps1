$users = get-adgroupmember "testgrp"

$results =foreach( $user in $users ){
    $account = $user.SamAccountName
    get-aduser -filter {SamAccountName -eq $account} -properties SamAccountName, "msDS-UserPasswordExpiryTimeComputed", passwordlastset, LastLogonTimeStamp, enabled | Select-Object -Property SamAccountName, @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}, passwordlastset, @{Name="lastLogon";; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd hh:mm:ss')}} , enabled 
}

$Results | ft