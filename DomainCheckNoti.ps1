$PingOnDomain = ping -n 1 10.1.98.0
$checkForLostPingRegex = [regex]::Match($PingOnDomain, "Lost = 0")
$CheckForUnreachableRegex = [regex]::Match($PingOnDomain, "Destination host unreachable")
$checkForLostPingRegexValue = $checkForLostPingRegex.Value
$CheckForUnreachableRegexVal = $CheckForUnreachableRegex.Value
$regPath = "HKCU:\Environment\DomainChecker"
$registryValueName = "CheckInDate"
$expirationTime = New-TimeSpan -Minutes 3
$date = Get-Date -UFormat "%Y-%m-%d %R"
$AuditPol = Auditpol /get /subcategory:"Process Creation"
$AuditPolRegex = [regex]::Match($AuditPol, "No Auditing")
if ($AuditPolRegex.Value){
    Auditpol /set /subcategory:"Process Creation" /success:enable /failure:disable
}
$getTask = Get-ScheduledTask -TaskName "CheckLastTimeOnDomain" -ErrorAction SilentlyContinue
if (!$getTask) {
    $XmlContents = Get-Content .\CheckLastTimeOnDomain.xml | Out-String
    Register-ScheduledTask -Xml $XmlContents -TaskPath "DomainCheckIn" -TaskName "CheckLastTimeOnDomain" | Out-Null
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
        } 
        # else {
        #     $answer = $wshell.Popup("Sorry You must of misread! Would you like to launch the VPN?",0,"CTI Domain Timeout", 0x30)
        # }
            # Add-Type -AssemblyName System.Windows.Forms
        # $global:balmsg = New-Object System.Windows.Forms.NotifyIcon
        # # $idpath = (Get-Process -id $pid).Path
        # $idpath = $MyInvocation.MyCommand.Path
        # $balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($idpath)
        # $balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
        # $balmsg.BalloonTipTitle = "Domain Timeout $Env:USERNAME"
        # $balmsg.BalloonTipText = "YO NERD CONNCET TO THE VPN OR SOMETIN"
        # $balmsg.Visible = $true
        # $balmsg.ShowBalloonTip(99999)
    }
}