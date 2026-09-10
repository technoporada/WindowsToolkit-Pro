# 1. Sprawdzenie krytycznych usług (Network, Search, Update)
Write-Host "[1/4] Weryfikacja kluczowych usług..." -ForegroundColor Cyan
$Services = @("WSearch", "Dhcp", "Dnscache", "wuauserv")
Get-Service -Name $Services | Select-Object Name, Status, StartType

# 2. Szybki test spójności bazy komponentów (bez naprawy)
Write-Host "`n[2/4] Weryfikacja stanu obrazu (CheckHealth)..." -ForegroundColor Cyan
# Uzasadnienie: Sprawdza tylko flagę uszkodzenia w rejestrze.
Dism /Online /Cleanup-Image /CheckHealth

# 3. Sprawdzenie błędów dysku w trybie 'Scan'
Write-Host "`n[3/4] Skanowanie powierzchniowe dysku (Online Scan)..." -ForegroundColor Cyan
# Uzasadnienie: Nie wymaga restartu, sprawdza strukturę plików w locie.
Repair-WindowsImage -Online -CheckHealth

# 4. Statystyki użycia pamięci i CPU
Write-Host "`n[4/4] Obciążenie systemu..." -ForegroundColor Cyan
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, @{Name="CPU(s)";Expression={$_.CPU}}, @{Name="RAM(MB)";Expression={[math]::Round($_.WorkingSet / 1MB,2)}}
