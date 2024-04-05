$addresses = "10.1.0.21", "10.1.0.22", "10.1.0.24"
$random = Get-Random -Minimum -0 -Maximum 3
write-host $random
$pingAdress = $addresses[$random]
write-host $pingAdress
$PingOnDomain = ping -n 1 $pingAdress
write-host $PingOnDomain