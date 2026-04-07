#Script out SQL agent jobs from powershell

#Original
# Load SMO extension
 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;
# Get List of sql servers to check
 
#$sqlservers = Get-Content "$Env:USERPROFILE\sqlservers.txt";
$sqlservers = Get-Content "D:\SQLJOBS\bvlprod4\Servers.txt";
 
# Loop through each sql server from sqlservers.txt
foreach($sqlserver in $sqlservers)
 
{
 
      # Create an SMO Server object
      $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
 
      # Jobs counts
      $totalJobCount = $srv.JobServer.Jobs.Count;
      $failedCount = 0;
      $successCount = 0;
 
      # For each jobs on the server
      foreach($job in $srv.JobServer.Jobs)
 
      {
            # Default write colour
            $colour = "Green";
            $jobName = $job.Name.Replace("/", "-");
            $jobName=$jobName
            $jobEnabled = $job.IsEnabled;
            $jobLastRunOutcome = $job.LastRunOutcome;
            $jobNameFile = "D:\SQLJOBS\bvlprod4\22122020\" + $jobName+".sql"
 
            Write-Host $job.Name
           # Write-Host "The location of the file is called " $jobNameFile
 
#           [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
#           $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
#           #$srv.JobServer.Jobs | foreach {$_.Script()} | out-file -path $path
            $job | foreach {$_.Script()} | out-file $jobNameFile
 
            # Set write text to red for Failed jobs
            if($jobLastRunOutcome -eq "Failed")
 
            {
 
                  $colour = "Red";
                  $failedCount += 1;
            }
 
           # elseif ($jobLastRunOutcome -eq "Succeeded")
            #{
             #     $successCount += 1;
           # }
 
           # Write-Host -ForegroundColor $colour "SERVER = $sqlserver JOB = $jobName ENABLED = $jobEnabled LASTRUN = $jobLastRunOutcome";
      }
 
      # Writes a summary for each SQL server
      Write-Host -ForegroundColor red "=========================================================================================";
      Write-Host -ForegroundColor red "$sqlserver total jobs = $totalJobCOunt, success count $successCount, failed jobs = $failedCount.";
      Write-Host -ForegroundColor red "=========================================================================================";
}




#Script out SQL agent jobs from powershell

#Original
# Load SMO extension
 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;
# Get List of sql servers to check
 
#$sqlservers = Get-Content "$Env:USERPROFILE\sqlservers.txt";
$sqlservers = Get-Content "D:\SQLJOBS\bvlprod4\Servers.txt";
 
# Loop through each sql server from sqlservers.txt
foreach($sqlserver in $sqlservers)
 
{
 
      # Create an SMO Server object
      $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
 
      # Jobs counts
      $totalJobCount = $srv.JobServer.Jobs.Count;
      $failedCount = 0;
      $successCount = 0;
 
      # For each jobs on the server
      foreach($job in $srv.JobServer.Jobs)
 
      {
            # Default write colour
            $colour = "Green";
            $jobName = $job.Name;
            $jobEnabled = $job.IsEnabled;
            $jobLastRunOutcome = $job.LastRunOutcome;
            $jobNameFile = "D:\SQLJOBS\bvlprod4\" + $jobName+".sql"
 
            Write-Host $job.Name
            Write-Host "The location of the file is called " $jobNameFile
 
#           [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
#           $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
#           #$srv.JobServer.Jobs | foreach {$_.Script()} | out-file -path $path
            $job | foreach {$_.Script()} | out-file $jobNameFile
 
            # Set write text to red for Failed jobs
            if($jobLastRunOutcome -eq "Failed")
 
            {
 
                  $colour = "Red";
                  $failedCount += 1;
            }
 
            elseif ($jobLastRunOutcome -eq "Succeeded")
            {
                  $successCount += 1;
            }
 
            Write-Host -ForegroundColor $colour "SERVER = $sqlserver JOB = $jobName ENABLED = $jobEnabled LASTRUN = $jobLastRunOutcome";
      }
 
      # Writes a summary for each SQL server
      Write-Host -ForegroundColor red "=========================================================================================";
      Write-Host -ForegroundColor red "$sqlserver total jobs = $totalJobCOunt, success count $successCount, failed jobs = $failedCount.";
      Write-Host -ForegroundColor red "=========================================================================================";
}

