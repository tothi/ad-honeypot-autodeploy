Set-Item WSMan:\localhost\Service\AllowUnencrypted $false
Write-Output "[+] Disabled Unencrypted WSMan over HTTP"

shutdown /s /t 5 /f /d p:4:1 /c "Packer Shutdown"
