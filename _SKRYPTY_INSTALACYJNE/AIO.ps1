<#
.SYNOPSIS
    Arek's All-In-One - Gaming, Dev, Security modes
.DESCRIPTION
    Narzędzie multipurpose: tryb gracza, programisty, administratora.
.PARAMETER Mode
    Tryb pracy: gamer, developer, admin
#>
param(
    [ValidateSet("gamer", "developer", "admin")]
    [string]$Mode = ""
)

# Domyślne ścieżki (konfigurowalne)
$SteamPath = "${env:ProgramFiles(x86)}\Steam\steam.exe"
$VSCodePath = "${env:ProgramFiles}\Microsoft VS Code\Code.exe"
$MMCPath = "${env:SystemRoot}\System32\mmc.exe"

# Wybór trybu jeśli nie podano
if (-not $Mode) {
    Write-Host "=== AREK'S AIO TOOLKIT ===" -ForegroundColor Cyan
    Write-Host "[1] Gamer    - Optymalizacja pod gry"
    Write-Host "[2] Developer - Środowisko dev"
    Write-Host "[3] Admin    - Zarządzanie systemem"
    $choice = Read-Host "Wybierz tryb (1/2/3)"
    switch ($choice) {
        "1" { $Mode = "gamer" }
        "2" { $Mode = "developer" }
        "3" { $Mode = "admin" }
        default { Write-Host "Nieprawidłowy wybór!" -ForegroundColor Red; exit 1 }
    }
}

Write-Host "Tryb: $Mode" -ForegroundColor Yellow

switch ($Mode) {
    "gamer" {
        Write-Host "Tryb Gracza: Optymalizuję system..." -ForegroundColor Green
        
        # Wyłącz zbędne usługi
        $services = @("SysMain", "WSearch", "DiagTrack")
        foreach ($svc in $services) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        }
        
        # Dodaj wyjątek dla Steam
        if (Test-Path $SteamPath) {
            New-NetFirewallRule -DisplayName "Steam Gaming" -Direction Outbound -Program $SteamPath -Action Allow -Enabled True -ErrorAction SilentlyContinue
            Write-Host "  ✅ Dodano wyjątek Steam" -ForegroundColor Green
        }
    }
    "developer" {
        Write-Host "Tryb Developera: Setup środowiska..." -ForegroundColor Green
        # Tutaj możesz dodać komendy dev
    }
    "admin" {
        Write-Host "Tryb Administratora: Zarządzanie..." -ForegroundColor Green
        # Otwórz MMC
        if (Test-Path $MMCPath) {
            Start-Process $MMCPath
        }
    }
}

Write-Host "`n✅ Gotowe!" -ForegroundColor Green
