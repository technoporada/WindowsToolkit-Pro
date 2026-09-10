#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Kompletne narzędzie do konfiguracji i optymalizacji środowiska deweloperskiego na Windows.
.DESCRIPTION
    Instaluje narzędzia, konfiguruje środowisko, usuwa bloatware i stosuje poprawki bezpieczeństwa.
.AUTHOR
    Arek & Gemini Agent
.VERSION
    2.2 (Final with Colors)
#>

param(
    [switch]$Verbose
)

# ==============================================================================
# SETUP & HELPER FUNCTIONS
# ==============================================================================

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    # Nowa, bezpieczna funkcja obsługi kolorów oparta na switch
    switch ($Color.ToUpper()) {
        'GREEN'   { Write-Host $Message -ForegroundColor Green }
        'YELLOW'  { Write-Host $Message -ForegroundColor Yellow }
        'RED'     { Write-Host $Message -ForegroundColor Red }
        'CYAN'    { Write-Host $Message -ForegroundColor Cyan }
        'MAGENTA' { Write-Host $Message -ForegroundColor Magenta }
        'HEADER'  { Write-Host $Message -ForegroundColor Magenta }
        'INFO'    { Write-Host $Message -ForegroundColor Cyan }
        'SUCCESS' { Write-Host $Message -ForegroundColor Green }
        'WARNING' { Write-Host $Message -ForegroundColor Yellow }
        'ERROR'   { Write-Host $Message -ForegroundColor Red }
        default   { Write-Host $Message }
    }
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-SystemRestorePoint {
    Write-ColoredOutput "\nTworzenie punktu przywracania systemu..." -Color Header
    try {
        $restoreService = Get-Service -Name "srservice" -ErrorAction SilentlyContinue
        if ($null -eq $restoreService -or $restoreService.Status -ne "Running") {
            Write-ColoredOutput "Włączanie usługi przywracania systemu..." -Color Info
            Enable-ComputerRestore -Drive "$env:SystemDrive"
            Start-Service -Name "srservice" -ErrorAction SilentlyContinue
        }
        Checkpoint-Computer -Description "Przed uruchomieniem skryptu DevSetup" -RestorePointType "MODIFY_SETTINGS"
        Write-ColoredOutput "Punkt przywracania utworzony pomyślnie!" -Color Success
    }
    catch {
        Write-ColoredOutput "Nie można utworzyć punktu przywracania: $_" -Color Error
        Write-ColoredOutput "Kontynuowanie na własne ryzyko..." -Color Warning
    }
}

# ==============================================================================
# MODULE: INSTALL DEV ENVIRONMENT
# ==============================================================================

function Install-Chocolatey {
    Write-ColoredOutput "=== Instalacja Chocolatey ===" -Color Header
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-ColoredOutput "Chocolatey już zainstalowane." -Color Success
        return
    }
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-ColoredOutput "Chocolatey zainstalowane pomyślnie." -Color Success
    }
    catch {
        Write-ColoredOutput "Błąd instalacji Chocolatey: $($_.Exception.Message)" -Color Error
        throw
    }
}

function Install-Python {
    Write-ColoredOutput "=== Instalacja Python 3.11+ ===" -Color Header
    try {
        choco install python --version=3.11.0 -y
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-ColoredOutput "Instalacja bibliotek Python..." -Color Info
        $libraries = @('pip', 'virtualenv', 'requests', 'flask', 'django', 'fastapi', 'numpy', 'pandas', 'pytest', 'selenium')
        foreach ($lib in $libraries) {
            Write-ColoredOutput "Instalacja: $lib" -Color Info
            pip install $lib --upgrade
        }
        Write-ColoredOutput "Python i biblioteki zainstalowane." -Color Success
    }
    catch {
        Write-ColoredOutput "Błąd instalacji Python: $($_.Exception.Message)" -Color Error
    }
}

function Install-Tools {
    Write-ColoredOutput "=== Instalacja narzędzi (Git, VSCode, Node.js) ===" -Color Header
    $tools = @('7zip', 'notepadplusplus', 'git', 'curl', 'wget', 'nodejs', 'vscode')
    foreach ($tool in $tools) {
        try {
            Write-ColoredOutput "Instalacja: $tool" -Color Info
            choco install $tool -y
        }
        catch {
            Write-ColoredOutput "Błąd instalacji $tool`: $($_.Exception.Message)" -Color Warning
        }
    }
}

function Install-WSL2 {
    Write-ColoredOutput "=== Instalacja WSL2 ===" -Color Header
    try {
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        wsl --install Ubuntu
        wsl --set-default-version 2
        Write-ColoredOutput "WSL2 zainstalowane. Wymagany restart systemu." -Color Warning
    }
    catch {
        Write-ColoredOutput "Błąd instalacji WSL2: $($_.Exception.Message)" -Color Error
    }
}

# ==============================================================================
# MODULE: DEBLOAT & OPTIMIZATION (Imported from Debloat script)
# ==============================================================================

function Remove-Bloatware {
    Write-ColoredOutput "\n[MODUŁ] Usuwanie Bloatware..." -Color Header
    $BloatwareApps = @("king.com.CandyCrushSaga", "Microsoft.MinecraftUWP", "Microsoft.GetHelp", "Microsoft.Messaging", "Microsoft.Microsoft3DViewer", "Microsoft.MicrosoftOfficeHub", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.Office.OneNote", "Microsoft.WindowsAlarms", "Microsoft.WindowsCamera", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo", "Microsoft.XboxApp")
    foreach ($App in $BloatwareApps) {
        try {
            Get-AppxPackage -Name $App -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $App | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            Write-ColoredOutput "Usunięto (lub nie znaleziono): $App" -Color Yellow
        } catch {
            Write-ColoredOutput "Nie można usunąć $App. Błąd: $_" -Color Red
        }
    }
    Write-ColoredOutput "Debloat zakończony!" -Color Success
}

function Disable-UnnecessaryServices {
    Write-ColoredOutput "\n[MODUŁ] Wyłączanie niepotrzebnych usług..." -Color Header
    $ServicesToDisable = @("DiagTrack", "dmwappushservice", "HomeGroupListener", "HomeGroupProvider", "RemoteRegistry", "XblAuthManager", "XblGameSave", "XboxNetApiSvc")
    foreach ($Service in $ServicesToDisable) {
        try {
            if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
                Write-ColoredOutput "Wyłączono usługę: $Service" -Color Yellow
            }
        } catch {
            Write-ColoredOutput "Nie można wyłączyć usługi $Service. Błąd: $_" -Color Red
        }
    }
    Write-ColoredOutput "Wyłączanie usług zakończone!" -Color Success
}

function Optimize-Registry {
    Write-ColoredOutput "\n[MODUŁ] Optymalizacja rejestru..." -Color Header
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0
        Write-ColoredOutput "Wyłączono telemetrię." -Color Yellow
    } catch { Write-ColoredOutput "Błąd przy wyłączaniu telemetrii." -Color Warning }
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
        Write-ColoredOutput "Wyłączono Cortanę." -Color Yellow
    } catch { Write-ColoredOutput "Błąd przy wyłączaniu Cortany." -Color Warning }
    Write-ColoredOutput "Optymalizacja rejestru zakończona!" -Color Success
}

# ==============================================================================
# MODULE: SECURITY & CONFIGURATION
# ==============================================================================

function Setup-Firewall {
    Write-ColoredOutput "\n[MODUŁ] Konfiguracja Windows Firewall..." -Color Header
    try {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        $suspiciousPorts = @(135, 139, 445, 3389)
        foreach ($port in $suspiciousPorts) {
            New-NetFirewallRule -DisplayName "Block-Port-$port" -Direction Inbound -Protocol TCP -LocalPort $port -Action Block -Enabled True -ErrorAction SilentlyContinue
        }
        Write-ColoredOutput "Firewall skonfigurowany (zablokowano podstawowe, ryzykowne porty)." -Color Success
    }
    catch {
        Write-ColoredOutput "Błąd konfiguracji firewall: $($_.Exception.Message)" -Color Error
    }
}

function Clear-PathVariable {
    Write-ColoredOutput "\n[MODUŁ] Czyszczenie zmiennej PATH..." -Color Header
    try {
        $envTypes = @("Machine", "User")
        foreach($type in $envTypes) {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", $type)
            $paths = $currentPath -split ";" | Where-Object { $_ -ne "" }
            $uniqueValidPaths = @()
            foreach ($path in $paths) {
                if (Test-Path $path -ErrorAction SilentlyContinue) {
                    if ($uniqueValidPaths -notcontains $path) {
                        $uniqueValidPaths += $path
                    }
                }
            }
            $newPath = $uniqueValidPaths -join ";"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, $type)
            Write-ColoredOutput "PATH ($type) wyczyszczony i zorganizowany." -Color Success
        }
    }
    catch {
        Write-ColoredOutput "Błąd podczas czyszczenia PATH: $_" -Color Error
    }
}

function Setup-PowerShellProfile {
    Write-ColoredOutput "\n[MODUŁ] Konfiguracja Profilu PowerShell..." -Color Header
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileContent = Get-Content -Path ".\powershell_profile.txt" -Raw

    if (Test-Path $profilePath) {
        Write-ColoredOutput "Wykryto istniejący profil PowerShell!" -Color Warning
        $action = Read-Host "Co chcesz zrobić? [D]opisz (bezpieczne), [N]adpisz (ryzykowne), [P]omiń"

        switch ($action.ToUpper()) {
            'D' {
                Add-Content -Path $profilePath -Value "`n# --- DODANE PRZEZ SKRYPT DEV-SETUP ---
$profileContent"
                Write-ColoredOutput "Dodano nowe aliasy i funkcje do istniejącego profilu." -Color Success
            }
            'N' {
                Set-Content -Path $profilePath -Value $profileContent
                Write-ColoredOutput "Profil PowerShell został nadpisany." -Color Success
            }
            'P' {
                Write-ColoredOutput "Pominięto modyfikację profilu PowerShell." -Color Info
            }
            default {
                Write-ColoredOutput "Nieprawidłowy wybór. Pominięto modyfikację profilu." -Color Warning
            }
        }
    } else {
        if (!(Test-Path (Split-Path $profilePath -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $profilePath -Parent) -Force
        }
        Set-Content -Path $profilePath -Value $profileContent
        Write-ColoredOutput "Utworzono i skonfigurowano nowy profil PowerShell: $profilePath" -Color Success
    }
}

# ==============================================================================
# MAIN MENU & EXECUTION
# ==============================================================================

function Main {
    if (-not (Test-Administrator)) {
        Write-ColoredOutput "Skrypt musi być uruchomiony jako Administrator!" -Color Error
        exit 1
    }

    while ($true) {
        Clear-Host
        Write-ColoredOutput "=== GŁÓWNE CENTRUM ZARZĄDZANIA ŚRODOWISKIEM v2.2 ===" -Color Header
        Write-ColoredOutput "\n--- INSTALACJA ŚRODOWISKA ---" -Color Cyan
        Write-ColoredOutput "[1] Instaluj Python, Git, VSCode, Node.js itp." -Color White
        Write-ColoredOutput "[2] Zainstaluj WSL2 (Ubuntu)" -Color White
        
        Write-ColoredOutput "\n--- OPTYMALIZACJA I BEZPIECZEŃSTWO ---" -Color Cyan
        Write-ColoredOutput "[3] Uruchom Debloat (usuwanie zbędnych aplikacji)" -Color White
        Write-ColoredOutput "[4] Zastosuj poprawki bezpieczeństwa (rejestr, usługi)" -Color White
        Write-ColoredOutput "[5] Skonfiguruj Firewall (blokowanie portów)" -Color White

        Write-ColoredOutput "\n--- NARZĘDZIA ---" -Color Cyan
        Write-ColoredOutput "[6] Skonfiguruj Profil PowerShell (aliasy i funkcje)" -Color White
        Write-ColoredOutput "[7] Wyczyść i zorganizuj zmienną środowiskową PATH" -Color White

        Write-ColoredOutput "\n-----------------------------------------" -Color Header
        Write-ColoredOutput "[A] Uruchom wszystko (Pełna instalacja i optymalizacja)" -Color Green
        Write-ColoredOutput "[Q] Wyjdź" -Color Red

        $choice = Read-Host "\nWybierz opcję"

        switch ($choice.ToUpper()) {
            '1' {
                Install-Chocolatey; Install-Python; Install-Tools
            }
            '2' { Install-WSL2 }
            '3' { Remove-Bloatware }
            '4' { Optimize-Registry; Disable-UnnecessaryServices }
            '5' { Setup-Firewall }
            '6' { Setup-PowerShellProfile }
            '7' { Clear-PathVariable }
            'A' {
                Write-ColoredOutput "Uruchamianie pełnej instalacji i konfiguracji..." -Color Green
                New-SystemRestorePoint
                Install-Chocolatey; Install-Python; Install-Tools; Install-WSL2
                Remove-Bloatware; Optimize-Registry; Disable-UnnecessaryServices
                Setup-Firewall; Clear-PathVariable; Setup-PowerShellProfile
                Write-ColoredOutput "\n=== WSZYSTKO ZAKOŃCZONE Pomyślnie ===" -Color Header
            }
            'Q' { break }
            default { Write-ColoredOutput "Nieprawidłowy wybór." -Color Red }
        }
        Write-ColoredOutput "\nNaciśnij dowolny klawisz, aby kontynuować..." -Color Gray
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

# Uruchomienie głównej funkcji
Main
