#Last time instance started running (useful for SSAS/SSRS/etc)
(Get-EventLog -LogName "System" -Source "Service Control Manager" -EntryType "Information" -Message "*MSSQLSERVER*running*" -Newest 1).TimeGenerated;

#Last restart message
Get-EventLog -LogName "System" -Source "user32" -EntryType "Information" -Newest 2 | format-table -auto -wrap;
