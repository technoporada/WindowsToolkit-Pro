## SCRIPT 20 - final-system-audit.ps1
# Runs several checks and produces summary JSON and optional apply/undo skeletons
$summary = @{}
$summary.Appx = (Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object Name,PackageFullName)
$summary.Services = @('DiagTrack','WSearch','W32Time') | ForEach-Object { $s=(Get-Service -Name $_ -ErrorAction SilentlyContinue); @{ Name=$_; Status = if($s){ $s.Status } else { 'NotFound' } } }
$summary.Path = [Environment]::GetEnvironmentVariable('PATH','Machine') -split ';' | Where-Object { $_ -and $_ -ne '' }
$summary.Listening = (Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort -Unique)
$outf = Join-Path $env:TEMP ('audit-{0}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $outf -Encoding ASCII
Write-Host "Audit saved: $outf"
Write-Host 'To generate apply/undo skeletons, run final-system-audit and then use the generated audit JSON as input to a tailor script.'

# End of toolkit
