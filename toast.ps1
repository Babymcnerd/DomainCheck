$heroimage = New-BTImage -Source 'C:\Users\ayden.mcneil\Documents\DomainCheck\CTI_Primary Logo.png' -HeroImage
$Text1 = New-BTText -Content  "Message from IT"
$Text2 = New-BTText -Content "You have not been on CTI domain in over 30 days, please use the VPN to connect to the VPN until you see a CHECKED IN notification"
$button = New-BTButton -Content "Launch VPN" -Arguments "C:\Program Files\Fortinet\FortiClient\FortiClient.exe" -ActivationType Protocol
$action = New-BTAction -Buttons $button
$Binding = New-BTBinding -Children $text1, $text2 -HeroImage $heroimage
$Visual = New-BTVisual -BindingGeneric $Binding
$Content = New-BTContent -Visual $Visual -Actions $action
Submit-BTNotification -Content $Content
