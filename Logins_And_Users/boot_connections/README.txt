First, you may need to intialize your powershell environment; this can be done by running powershell as administrator, then running
Set-executionpolicy RemoteSigned

Second, open the "CheckLogins.txt" and "get-sessions.txt" files and save them as .ps1 files (save as > all types, then add .ps1 extension).

Then, make sure that the directory structure is C:\powershell\boot_connections\<files>

Also, make sure the sqlservers.txt file is up to date with all SQL Servers.

From there, use CD in powershell to path to the folder. Then execute the checklogins script, and pass the user you are looking for when prompted. 

Example:

Windows PowerShell
Copyright (C) 2009 Microsoft Corporation. All rights reserved.

PS C:\Users\npatti> cd C:\Powershell\boot_connections
PS C:\Powershell\boot_connections> .\check_connections.ps1

cmdlet check_connections.ps1 at command pipeline position 1
Supply values for the following parameters:
user: 

If you want to disconnect the session, go to the folder, and find the text file named for the user. There will be a logoff command, which you can run direclty in powershell. In the example below, you run just the "logoff" line to perform the logoff.

Example:
srvdbaitp01
logoff rdp-tcp#2 /server:srvdbaitp01


Alternatively, you can change the "CheckLogins.ps1" file, uncommenting the "# Invoke-Expression $logoffCMD" line, and it will perform the logoff as it finds connections.