$randomSleepTime = Get-Random -Minimum -0 -Maximum 10
Start-Sleep -seconds $randomSleepTime
# $addresses = "10.1.0.21", "10.1.0.22", "10.1.0.24"
$addresses = "10.1.0.98", "10.1.0.98", "10.1.0.98"
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
    New-ItemProperty -Path $regPath -Name $registryValueName -PropertyType Expandstring -Value "2024-1-1 01:01" -Force | Out-Null
}
if ($checkForLostPingRegexValue -and (!$CheckForUnreachableRegexVal)) {
    New-ItemProperty -Path $regPath -Name $registryValueName -PropertyType Expandstring -Value $date -Force | Out-Null
}
else {
    $lastCheckInDate = (Get-ItemProperty -Path $regPath).$registryValueName
    $timeSinceLastCheckIn = (New-TimeSpan -start $lastCheckInDate -end $date)
    if ($timeSinceLastCheckIn -ge $expirationTime) {
        $Users = query user

        $Users = $Users | ForEach-Object {
            (($_.trim() -replace ">" -replace "(?m)^([A-Za-z0-9]{3,})\s+(\d{1,2}\s+\w+)", '$1  none  $2' -replace "\s{2,}", "," -replace "none", $null))
        } | ConvertFrom-Csv

        $loggedInUsers = New-Object -TypeName System.Collections.ArrayList

        foreach ($User in $Users) {
            $loggedInUsers.Add([PSCustomObject]@{
                    Username = $User.USERNAME
                })
        }
        $usernameToUse = $loggedinUsers[0].USERNAME
        msg $loggedinUsers[0].USERNAME "$usernameToUse You have not connected to the CTI domain in over 30 days, please use the VPN and connect to the domain. Thank you!" 
        # foreach ($loggedin in $loggedInUsers){
        #     Write-Host "Pinging " + $loggedin.Username 
        #     if (!($loggedin.USERNAME -eq "development" -or $loggedin.USERNAME -eq "cti")){
        #         msg $loggedin.USERNAME "You have not connected to the CTI domain in over 30 days"
        #     }
        # }
        # Start-Process -FilePath "C:\Program Files\Fortinet\FortiClient\FortiClient.exe" | Out-Null
    }
}