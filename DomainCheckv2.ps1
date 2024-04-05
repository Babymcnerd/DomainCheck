$randomSleepTime = Get-Random -Minimum -0 -Maximum 10
Start-Sleep -seconds $randomSleepTime
$addresses = "10.1.0.21", "10.1.0.22", "10.1.0.24"
$random = Get-Random -Minimum -0 -Maximum 3
$pingAdress = $addresses[$random]
$PingOnDomain = ping -n 1 $pingAdress
write-host $PingOnDomain
$checkForLostPingRegex = [regex]::Match($PingOnDomain, "Lost = 0")
$CheckForUnreachableRegex = [regex]::Match($PingOnDomain, "Destination host unreachable")
$checkForLostPingRegexValue = $checkForLostPingRegex.Value
$CheckForUnreachableRegexVal = $CheckForUnreachableRegex.Value
$regPath = "HKLM:\System\DomainChecker"
$registryValueName = "CheckInDate"
$expirationTime = New-TimeSpan -Days 3
$date = Get-Date -UFormat "%Y-%m-%d %R"
$AuditPol = Auditpol /get /subcategory:"Process Creation"
$AuditPolRegex = [regex]::Match($AuditPol, "No Auditing")
if ($AuditPolRegex.Value){
    Auditpol /set /subcategory:"Process Creation" /success:enable /failure:disable
}
$getTask = Get-ScheduledTask -TaskName "CheckLastTimeOnDomain" -ErrorAction SilentlyContinue
if (!$getTask) {
    $XmlContents = Get-Content .\CheckLastTimeOnDomain.xml | Out-String
    $fullTask = Register-ScheduledTask -Xml $XmlContents -TaskPath "DomainCheckIn" -TaskName "CheckLastTimeOnDomain" | Out-Null
}
if (!(Test-Path -Path $regPath)) {
    New-Item -Path $regPath | Out-Null
}
if (!(Get-ItemProperty -Path $regPath)){
    New-ItemProperty -Path $regPath -Name $registryValueName -PropertyType Expandstring -Value "2024-1-1 01:01" -Force | Out-Null
}
if ($checkForLostPingRegexValue -and (!$CheckForUnreachableRegexVal)) {
    New-ItemProperty -Path $regPath -Name $registryValueName -PropertyType Expandstring -Value $date -Force | Out-Null
} else {
    $lastCheckInDate = (Get-ItemProperty -Path $regPath).$registryValueName
    $timeSinceLastCheckIn = (New-TimeSpan -start $lastCheckInDate -end $date)
    if ($timeSinceLastCheckIn -ge $expirationTime){
        $wshell = New-Object -ComObject Wscript.Shell
        $answer = $wshell.Popup("You have not connected to the CTI domain in over 30 days. Would you like to launch the VPN?",0,"CTI Domain Timeout", 0x1214)
        if ($answer -eq 6){
            Start-Process -FilePath "C:\Program Files\Fortinet\FortiClient\FortiClient.exe" | Out-Null
            $wshell.Popup("Please Connect for at least 10 minutes! If you have any issues please put in an IT helpdesk ticket at help.cti.com",30,"Starting VPN", 0x1220)
        } 
    }
}