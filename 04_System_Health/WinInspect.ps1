# WinInspect PS5 Compatible
Write-Host "=== WIN INSPECTOR ==="
Write-Host "Date:" (Get-Date)
Write-Host "------------------------"

# 1) Appx Packages
Write-Host "`n--- Appx Packages (All Users) ---"
Try {
    $apps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select Name, PackageFullName, InstallLocation
    if ($apps.Count -eq 0) { Write-Host "No Appx packages found or insufficient permissions." }
    else { $apps | Format-Table -AutoSize }
} Catch {
    Write-Host "Error retrieving Appx packages: $_"
}

# 2) Services
Write-Host "`n--- Selected Services ---"
$servicesCheck = @("DiagTrack","WSearch","W32Time")
foreach ($s in $servicesCheck){
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($svc) { Write-Host ($svc.Name + " : " + $svc.Status) }
    else { Write-Host ($s + " : Not Found") }
}

# 3) PATH entries
Write-Host "`n--- PATH entries (Machine) ---"
$path = [Environment]::GetEnvironmentVariable("PATH","Machine") -split ';' | Where-Object { $_ -and $_ -ne '' }
foreach ($p in $path){
    $exists = Test-Path $p
    if ($exists) { $status = "Exists" } else { $status = "Missing" }
    Write-Host ($p + " -> " + $status)
}

# 4) Listening TCP ports
Write-Host "`n--- Listening TCP ports ---"
Try {
    $tcp = Get-NetTCPConnection -State Listen -ErrorAction Stop | Select LocalAddress, LocalPort
    if ($tcp.Count -eq 0) { Write-Host "No listening ports or insufficient permissions." }
    else { $tcp | Format-Table -AutoSize }
} Catch {
    Write-Host "Cannot retrieve listening ports: $_"
}

Write-Host "`n=== END OF SCAN ==="
Write-Host "Manually review packages or paths if you want to remove/change anything."
