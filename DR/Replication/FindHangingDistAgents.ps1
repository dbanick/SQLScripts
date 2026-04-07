#this script was created for an issue where the distribution process was killed in windows but still a zombie process in SQL. This will identify those zombie processes for you to kill manually

$w = get-process distrib

$s = invoke-sqlcmd -ServerInstance WXDISTDBSQLPRE -query "select s.host_process_id from sys.dm_exec_sessions s
where program_name in (
	select j.name from msdb..sysjobs j
	join msdb..syscategories c on j.category_id = c.category_id
	where c.name = 'REPL-Distribution'
)
order by s.host_process_id asc
"

$win = $w.id
$sql = $s.host_process_id

write-host "Windows has $($win.Count) distribution processes"
write-host "SQL has $($sql.Count) distribution processes"


$h = $w.id | where { $s.host_process_id -notcontains $_ }

Write-host "Here are a list of all Windows PIDS that do not exist in SQL (if any) and are likely hung"
$h