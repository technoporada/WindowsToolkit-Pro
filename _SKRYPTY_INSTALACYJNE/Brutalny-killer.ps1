# Brutalny-killer.ps1
# Pokazuje top 10 procesow wg pamieci i CPU, pyta czy zabic top-proces i go zabija.
# Uwaga: zapisac wszystko co wazne przed uruchomieniem.

# Lista procesow chronionych (nie zabijaj)
$protected = @('System','Idle','explorer','winlogon','lsass','csrss','services','smss','Registry','dwm','spoolsv','wininit')

# Pobierz top10 wg pamieci (WS) i CPU
$topMem = Get-Process | Where-Object { $protected -notcontains $_.ProcessName } | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Id,ProcessName,@{Name='MemMB';Expression={[math]::Round($_.WorkingSet64/1MB,1)}},CPU
$topCpu = Get-Process | Where-Object { $protected -notcontains $_.ProcessName } | Sort-Object CPU -Descending | Select-Object -First 10 Id,ProcessName,@{Name='CPUsec';Expression={[math]::Round($_.CPU,1)}},@{Name='MemMB';Expression={[math]::Round($_.WorkingSet64/1MB,1)}}

Write-Host "`n=== TOP 10 wg PAMIĘCI (MB) ==="
$topMem | Format-Table -AutoSize
Write-Host "`n=== TOP 10 wg CPU (s) ==="
$topCpu | Format-Table -AutoSize

# Wybierz największego wg pamięci (pierwszy z topMem)
$victim = $topMem | Select-Object -First 1

if (-not $victim) {
    Write-Host "`nNie znaleziono procesu do zabicia." -ForegroundColor Yellow
    exit
}

# Ostrzeżenie, pokaz info
Write-Host "`nZamierzasz zabić: Id=$($victim.Id) Name=$($victim.ProcessName) Mem=$($victim.MemMB)MB" -ForegroundColor Cyan
$ans = Read-Host "Chcesz zabić tego gnojka? (Y/N)"

if ($ans -match '^[Yy]') {
    try {
        Stop-Process -Id $victim.Id -Force -ErrorAction Stop
        Write-Host "`nKutasa dostał: proces $($victim.ProcessName) (Id $($victim.Id)) został zabity." -ForegroundColor Green
    } catch {
        Write-Host "`nBłąd przy zabijaniu procesu: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`nSpoko, anulowano." -ForegroundColor Yellow
}

# Opcjonalnie — jeśli chcesz automatycznie zabić bez pytania, odkomentuj poniższe:
# Stop-Process -Id $victim.Id -Force
