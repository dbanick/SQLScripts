#Requires Server role RSAT tools installed
 
Get-ADGroupMember -Identity "Vendor_DatabaseSupport" | Get-ADUser -Properties "DisplayName","PasswordExpired","LockedOut","LastLogonDate","msDS-UserPasswordExpiryTimeComputed" | 
Select-Object -Property "Displayname","PasswordExpired","LockedOut","LastLogonDate",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | Format-Table