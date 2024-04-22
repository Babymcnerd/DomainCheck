$randomSleepTime = Get-Random -Minimum -0 -Maximum 10
Start-Sleep -seconds $randomSleepTime
$addresses = "10.1.0.21", "10.1.0.22", "10.1.0.24"
# $addresses = "10.1.0.98", "10.1.0.98", "10.1.0.98"
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
$expirationTime = New-TimeSpan -Minutes 20
$date = Get-Date -UFormat "%Y-%m-%d %R"
$AuditPol = Auditpol /get /subcategory:"Process Creation"
$AuditPolRegex = [regex]::Match($AuditPol, "No Auditing")
Install-Module -Name RunAsUser -Confirm:$False -Force
Install-Module -Name BurntToast -Confirm:$False -Force
if ($AuditPolRegex.Value) {
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
if (!(Get-ItemProperty -Path $regPath)) {
    New-ItemProperty -Path $regPath -Name $registryValueName -PropertyType Expandstring -Value $date -Force | Out-Null
}
if ($checkForLostPingRegexValue -and (!$CheckForUnreachableRegexVal)) {
    $lastCheckInDate = (Get-ItemProperty -Path $regPath).$registryValueName
    $timeSinceLastCheckIn = (New-TimeSpan -start $lastCheckInDate -end $date)
    $timeUntilNextPromp = $lastCheckInDate + (New-TimeSpan -Days 30)
    if ($timeSinceLastCheckIn -ge $expirationTime) {
        invoke-ascurrentuser -UseWindowsPowerShell {    
            $heroimage = New-BTImage -Source 'C:\ProgramData\Quest\KACE\kbots_cache\packages\kbots\90\CTI_Primary Logo.png' -HeroImage
            $Text1 = New-BTText -Content  "Message from IT"
            $Text2 = New-BTText -Content "You have checked into the domain! You will be prompted to check in again on $timeUntilNextPromp"
            $Binding = New-BTBinding -Children $text1, $text2 -HeroImage $heroimage
            $Visual = New-BTVisual -BindingGeneric $Binding
            $button = New-BTButton -Content "Launch VPN" -ImageUri "C:\Program Files\Fortinet\FortiClient\SoftwareInventory\854619877.png" -Arguments "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"
            $Content = New-BTContent -Visual $Visual
            New-BurntToastNotification -Content $Content -Button $button
        }
    }
    New-ItemProperty -Path $regPath -Name $registryValueName -PropertyType Expandstring -Value $date -Force | Out-Null
}
else {
    $lastCheckInDate = (Get-ItemProperty -Path $regPath).$registryValueName
    $timeSinceLastCheckIn = (New-TimeSpan -start $lastCheckInDate -end $date)
    if ($timeSinceLastCheckIn -ge $expirationTime) {
        invoke-ascurrentuser -UseWindowsPowerShell {    
            $heroimage = New-BTImage -Source 'C:\ProgramData\Quest\KACE\kbots_cache\packages\kbots\90\CTI_Primary Logo.png' -HeroImage
            $Text1 = New-BTText -Content  "Message from IT"
            $Text2 = New-BTText -Content "You have not been on CTI domain since $lastCheckInDate, please use the VPN to connect to the CTI Domain until you see a CHECKED IN notification"
            $Binding = New-BTBinding -Children $text1, $text2 -HeroImage $heroimage
            $Visual = New-BTVisual -BindingGeneric $Binding
            $Content = New-BTContent -Visual $Visual
            Submit-BTNotification -Content $Content
        }
    }
}