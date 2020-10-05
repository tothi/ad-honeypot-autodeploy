Write-Host "[*] Fixing CPU spiking caused by .NET Runtime Optimization Service"
Get-ChildItem $env:SystemRoot/Microsoft.net/NGen.exe -recurse | %{ & $_ executeQueuedItems }
