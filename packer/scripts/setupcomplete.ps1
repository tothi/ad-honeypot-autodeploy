Write-Output "[*] Installing extra VirtIO drivers..."

<# this was fixed in new VirtIO release, no need to install custom cert
$driverFile = "c:\windows\temp\extra\balloon.sys"
$certFile = "c:\windows\temp\extra\redhat.cer"
$exportType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
$cert = (Get-AuthenticodeSignature $driverFile).SignerCertificate;
[System.IO.File]::WriteAllBytes($certFile, $cert.Export($exportType));
Import-Certificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
#>

pnputil -i -a c:\windows\temp\extra\balloon.inf
pnputil -i -a c:\windows\temp\extra\qxldod.inf
pnputil -i -a c:\windows\temp\extra\viorng.inf
pnputil -i -a c:\windows\temp\extra\vioser.inf

Write-Output "[*] Disabling Auto-Hibernate..."
powercfg -hibernate OFF

Write-Output "[*] Enabling Windows Time Service"
Set-Service -Name w32time -StartupType Automatic
sc.exe triggerinfo w32time delete

Write-Output "[*] Checking for Windows 10..."
If ([Environment]::OSVersion.Version -ge (new-object 'Version' 10,0)) {
  Write-Output "[+] Validated Windows 10"
  Write-Output "[*] Disabling Windows AutoUpdate"
  New-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows -Name WindowsUpdate
  New-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name AU
  New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoUpdate -Value 1
  Write-Output "[*] Disabling Windows Defender"
  Set-MpPreference -DisableIntrusionPreventionSystem $true `
                   -DisableIOAVProtection $true `
                   -DisableRealtimeMonitoring $true `
                   -DisableScriptScanning $true `
                   -EnableControlledFolderAccess Disabled `
                   -EnableNetworkProtection AuditMode `
                   -Force -MAPSReporting Disabled `
                   -SubmitSamplesConsent NeverSend
} Else {
  Write-Output "[!] Older Windows detected"
}

Write-Output "[*] Allowing incoming WinRM on Any Profile in Firewall..."
New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -Profile Any

Write-Output "[*] Enabling RDP..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

Write-Output "[+] Setup complete. Cleaning up files..."
Remove-Item -Recurse -Force -Path c:/windows/temp/extra
