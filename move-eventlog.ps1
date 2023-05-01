<#
.SYNOPSIS 
Move Event Log Locations
.DESCRIPTION 
Use this script to move the default location for event logs.
This must be run in an elevated powershell window or it will not write to the registry or restart the eventlog service.
.PARAMETER LogName
This parameter is the name of the event log. You can use Security, Application, System, Setup, or any of the logs found in the event logs channels.
.PARAMETER Path
This is the fully qualified path you want the new logs to be stored in. Do not include the filename. The path must already exist.
.PARAMETER ComputerList
A text file that contains a new-line separated list of computers on which to run the script. 
.EXAMPLE
.\move-eventlog.ps1 -LogName Security -Path Q:\Windows\EventLogs
.EXAMPLE
.\move-eventlog.ps1 -LogName Microsoft-Windows-PowerShell/Operational -Path C:\Windows\EventLogs
.EXAMPLE
.\move-eventlog.ps1 -LogName Application -Path Q:\Windows\EventLogs -ComputerList .\computers.txt
.NOTES
Author: Stephen Harper
Company: Alpha Omega
Client: Department of State
Date: May 1, 2023
Version 1.0
#>

param(
    # Parameter help description
    [Parameter(Mandatory, HelpMessage = "Enter the log you want to reconfigure.`nExample 'Microsoft-Windows-PowerShell/Operational'.")]
    [String] $LogName,
    [Parameter(Mandatory, HelpMessage = "Enter the path where you want these logs to be located.")]
    [String] $Path,
    [Parameter(HelpMessage = "The file that has a list of computers to run this script on.")]
    [String] $ComputerList = ""
)

if($ComputerList -ne ""){
    $Computers = get-content $ComputerList
}
else {
    $Computers = localhost
}
foreach($Computer in $Computers){
    Enter-PSSession $Computer

    $MainLogs = @("application","system","security","setup", "forwarded events")
    if($MainLogs -notcontains $Logname.toLower()){
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels"
    }   
    else
    {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog"
    }
    if(Test-Path ("$regPath\$LogName")){
        write-host "After looking in the registry for the event log $logname, I see it is present in the channels key."
        write-host "I will now configure the registry to use the new path for the event log."
        $LogFileName = $LogName -replace '/','%4'
        
        New-ItemProperty "$regPath\$logName" -Name "AutoBackupLogFiles" -Value "1" -PropertyType "DWord"
        New-ItemProperty "$regPath\$logName" -Name "Flags" -Value "1" -PropertyType "DWord"
        Set-ItemProperty -Path "$regPath\$LogName" -Name "File" -value "$Path\$LogFileName.evtx"
        restart-service EventLog
        write-host "I have completed the change. Please validate that the eventlog is in the correct location."
        exit 0
    }
    else{
        Write-Host "The log $logname does not exist."
        exit 1
    }
}
