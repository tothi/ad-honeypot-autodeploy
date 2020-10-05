# bootstrap script for win2012r2 and win2016 packer image

New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force
Write-Output "[*] New Network Window Popup -> OFF"

$ifaceinfo = Get-NetConnectionProfile
Set-NetConnectionProfile -InterfaceIndex $ifaceinfo.InterfaceIndex -NetworkCategory Private 
Write-Output "[*] NetConnectionProfile -> Private"

Set-WSManQuickConfig -Force
Set-Item WSMan:\localhost\Service\AllowUnencrypted $true
Write-Output "[!] INSECURE!!! WARNING!!! AllowUnencrypted WSMan over HTTP"
