$output = ping -n 1 10.1.0.3
$regex = [regex]::Match($output, "Lost = 0")
$regex2 = [regex]::Match($output, "Destination host unreachable")
$substring = $regex.Value
$substring2 = $regex2.Value
Write-Host $substring2
$regPath = "HKCU:\Environment\DomainChecker"
$name = "CheckInDate"
$expirationTime = 3
$date = Get-Date -UFormat "%Y-%m-%d %R"
$lastCheckInDate = 0
$daysSinceLastCheckIn = 0
$path = Get-Location
$getTask = Get-ScheduledTask -TaskName "CheckLastTimeOnDomain" -ErrorAction SilentlyContinue
if ($getTask) {
    # actions here
} elseif (!$getTask) {
    $CIMTriggerClass = Get-CimClass -ClassName
    $eventtrigger 
    $trigger = New-ScheduledTaskTrigger -Daily -At "8:00 AM"
    $Action = New-ScheduledTaskAction -Execute "$path\DomainCheck.exe"
    # $ExecTimeLimite = New-TimeSpan -Seconds 10
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
    $Settings.CimInstanceProperties.Item('MultipleInstances').Value = 3
    $task = Register-ScheduledTask -Action $Action -TaskName "CheckLastTimeOnDomain" -Trigger $trigger -TaskPath "DomainCheckIn" -Settings $settings
    $task.Triggers.Repetition.Duration = "P1D"
    $task.Triggers.Repetition.Interval = "PT1M"
    $task | Set-ScheduledTask | Out-Null
}

# Check if Key exists and create if it doesnt
if (Test-Path -Path $regPath) {
    # Key already exists {actions here if wanted}
} else {
    New-Item -Path $regPath | Out-Null
}
# Check if value exists and create if it doesnt
if (Get-ItemProperty -Path $regPath){
    #value exists
} else {
    New-ItemProperty -Path $regPath -Name $name -PropertyType Expandstring -Value "2024-1-1 01:01" -Force | Out-Null
}
# If ping succeeds then set new CheckInDate value
if ($substring -and (!$substring2)) {
    # Write-Host "here"
    New-ItemProperty -Path $regPath -Name $name -PropertyType Expandstring -Value $date -Force | Out-Null
# If ping fails check last checkin time
} else {
    # Write-Host "there"
    $lastCheckInDate = (Get-ItemProperty -Path $regPath).$name
    $daysSinceLastCheckIn = (New-TimeSpan -start $lastCheckInDate -end $date).Minutes

    # Send Popup Notification
    if ([int]$daysSinceLastCheckIn -ge $expirationTime){
        Add-Type -AssemblyName System.Windows.Forms
        $global:balmsg = New-Object System.Windows.Forms.NotifyIcon
        $idpath = (Get-Process -id $pid).Path
        $balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($idpath)
        $balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
        $balmsg.BalloonTipTitle = "Domain Timeout $Env:USERNAME"
        $balmsg.BalloonTipText = "YO NERD CONNCET TO THE VPN OR SOMETIN"
        $balmsg.Visible = $true
        $balmsg.ShowBalloonTip(99999)
    }
}