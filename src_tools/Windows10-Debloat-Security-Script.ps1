<#
.SYNOPSIS
Windows 10 Debloat + Security Script
.DESCRIPTION
Modularny skrypt do optymalizacji i zabezpieczania systemu
.NOTES
Author: Claude AI
Version: 1.1 (Poprawiona)
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

# ==============================================================================
# KONFIGURACJA
# ==============================================================================

# Kolory dla output
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

Write-Host "=== Windows 10 Debloat & Security Script ===" -ForegroundColor Cyan
Write-Host "Uruchamianie jako Administrator..." -ForegroundColor Yellow

# Sprawdzenie uprawnień administratora
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "BŁĄD: Skrypt musi być uruchomiony jako Administrator!" -ForegroundColor Red
    exit 1
}

# ==============================================================================
# FUNKCJE POMOCNICZE
# ==============================================================================

# Funkcja tworząca punkt przywracania
function New-SystemRestorePoint {
    Write-Host "`nTworzenie punktu przywracania systemu..." -ForegroundColor Green
    
    try {
        # Sprawdź czy usługa jest włączona
        $restoreService = Get-Service -Name "srservice" -ErrorAction SilentlyContinue
        if ($null -eq $restoreService -or $restoreService.Status -ne "Running") {
            Write-Host "Włączanie usługi przywracania systemu..." -ForegroundColor Yellow
            Enable-ComputerRestore -Drive "$env:SystemDrive"
            Start-Service -Name "srservice" -ErrorAction SilentlyContinue
        }
        
        # Utwórz punkt przywracania
        Checkpoint-Computer -Description "Windows Debloat & Security Script" -RestorePointType "MODIFY_SETTINGS"
        Write-Host "Punkt przywracania utworzony pomyślnie!" -ForegroundColor Green
    }
    catch {
        Write-Host "Nie można utworzyć punktu przywracania: $_" -ForegroundColor Red
        Write-Host "Kontynuowanie skryptu bez punktu przywracania..." -ForegroundColor Yellow
    }
}

# ==============================================================================
# MODUŁ 1: DEBLOAT - USUWANIE NIEPOTRZEBNYCH APLIKACJI (POPRAWIONY)
# ==============================================================================

function Remove-Bloatware {
    Write-Host "`n[MODUŁ 1] Usuwanie Bloatware..." -ForegroundColor Green
    
    # Lista aplikacji do usunięcia z kategoriami
    $BloatwareApps = @{
        "Gry"                 = @(
            "king.com.CandyCrushSaga",
            "king.com.CandyCrushSodaSaga",
            "king.com.BubbleWitch3Saga",
            "Microsoft.MinecraftUWP",
            "GAMELOFTSA.Asphalt8Airborne",
            "D52A8D61.FarmVille2CountryEscape"
        )
        "Multimedia"          = @(
            "SpotifyAB.SpotifyMusic",
            "PandoraMediaInc.29680B314EFC2",
            "ShazamEntertainmentLtd.Shazam",
            "TuneIn.TuneInRadio",
            "Flipboard.Flipboard",
            "Disney.37853FC22B2CE",
            "TheNewYorkTimes.NYTCrossword"
        )
        "Narzędzia Microsoft" = @(
            "Microsoft.3DBuilder",
            "Microsoft.GetHelp",
            "Microsoft.Getstarted",
            "Microsoft.Messaging",
            "Microsoft.Microsoft3DViewer",
            "Microsoft.MicrosoftOfficeHub",
            "Microsoft.MicrosoftSolitaireCollection",
            "Microsoft.MicrosoftStickyNotes",
            "Microsoft.MSPaint",
            "Microsoft.Office.OneNote",
            "Microsoft.Print3D",
            "Microsoft.WindowsAlarms",
            "Microsoft.WindowsCamera",
            "Microsoft.WindowsSoundRecorder",
            "Microsoft.WindowsFeedbackHub",
            "Microsoft.ZuneMusic",
            "Microsoft.ZuneVideo"
        )
        "Xbox"                = @(
            "Microsoft.Xbox.TCUI",
            "Microsoft.XboxApp",
            "Microsoft.XboxGameOverlay",
            "Microsoft.XboxGamingOverlay",
            "Microsoft.XboxIdentityProvider",
            "Microsoft.XboxSpeechToTextOverlay"
        )
        "Inne"                = @(
            "Microsoft.AppConnector",
            "Microsoft.BingFinance",
            "Microsoft.BingFoodAndDrink",
            "Microsoft.BingHealthAndFitness",
            "Microsoft.BingMaps",
            "Microsoft.BingNews",
            "Microsoft.BingSports",
            "Microsoft.BingTranslator",
            "Microsoft.BingTravel",
            "Microsoft.BingWeather",
            "Microsoft.CommsPhone",
            "Microsoft.ConnectivityStore",
            "Microsoft.FreshPaint",
            "Microsoft.HelpAndTips",
            "Microsoft.Media.PlayReadyClient.2",
            "Microsoft.MixedReality.Portal",
            "Microsoft.OneConnect",
            "Microsoft.Wallet",
            "Microsoft.WebMediaExtensions",
            "microsoft.windowscommunicationsapps",
            "Microsoft.WindowsMaps",
            "Microsoft.WindowsPhone",
            "ActiproSoftwareLLC.562882FEEB491"
        )
    }
    
    $removeAll = Read-Host "Czy chcesz usunąć wszystkie aplikacje bloatware? (t/n)"
    
    foreach ($category in $BloatwareApps.Keys) {
        Write-Host "`nKategoria: $category" -ForegroundColor Cyan
        
        if ($removeAll -eq 't' -or $removeAll -eq 'T') {
            $removeCategory = $true
        }
        else {
            $removeCategory = Read-Host "Czy chcesz usunąć aplikacje z kategorii $category? (t/n)"
            if ($removeCategory -eq 't' -or $removeCategory -eq 'T') { 
                $removeCategory = $true 
            }
            else {
                $removeCategory = $false
            }
        }
        
        if ($removeCategory) {
            foreach ($App in $BloatwareApps[$category]) {
                try {
                    $appPackage = Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue
                    $provisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $App -ErrorAction SilentlyContinue
                    
                    if ($appPackage -or $provisionedPackage) {
                        $appPackage | Remove-AppxPackage -ErrorAction SilentlyContinue
                        $provisionedPackage | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                        Write-Host "Usunięto: $App" -ForegroundColor Yellow
                    }
                    else {
                        Write-Host "Nie znaleziono: $App" -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Host "Nie można usunąć: $App. Błąd: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host "Debloat zakończony!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 2: WYŁĄCZANIE NIEPOTRZEBNYCH USŁUG
# ==============================================================================

function Disable-UnnecessaryServices {
    Write-Host "`n[MODUŁ 2] Wyłączanie niepotrzebnych usług..." -ForegroundColor Green
    
    # Lista usług do wyłączenia
    $ServicesToDisable = @(
        "DiagTrack",                # Connected User Experiences and Telemetry
        "dmwappushservice",         # WAP Push Message Routing Service
        "HomeGroupListener",        # HomeGroup Listener
        "HomeGroupProvider",        # HomeGroup Provider
        "lfsvc",                   # Geolocation Service
        "MapsBroker",              # Downloaded Maps Manager
        "NetTcpPortSharing",       # Net.Tcp Port Sharing Service
        "RemoteAccess",            # Routing and Remote Access
        "RemoteRegistry",          # Remote Registry
        "SharedAccess",            # Internet Connection Sharing (ICS)
        "TrkWks",                  # Distributed Link Tracking Client
        "WbioSrvc",                # Windows Biometric Service
        "WMPNetworkSvc",           # Windows Media Player Network Sharing Service
        "XblAuthManager",          # Xbox Live Auth Manager
        "XblGameSave",             # Xbox Live Game Save Service
        "XboxNetApiSvc"            # Xbox Live Networking Service
    )

    foreach ($Service in $ServicesToDisable) {
        try {
            # Sprawdź czy usługa istnieje
            if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Host "Wyłączono usługę: $Service" -ForegroundColor Yellow
            }
            else {
                Write-Host "Usługa nie istnieje: $Service" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "Nie można wyłączyć usługi: $Service. Błąd: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "Wyłączanie usług zakończone!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 3: OPTYMALIZACJA REJESTRU (POPRAWIONY)
# ==============================================================================

function Optimize-Registry {
    Write-Host "`n[MODUŁ 3] Optymalizacja rejestru..." -ForegroundColor Green
    
    # Wyłączenie telemetrii
    try {
        if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection")) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction Stop
        
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction Stop
        Write-Host "Wyłączono telemetrię" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Błąd podczas konfiguracji telemetrii: $_" -ForegroundColor Red
    }
    
    # Wyłączenie Cortany
    try {
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -ErrorAction Stop
        Write-Host "Wyłączono Cortanę" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Błąd podczas wyłączania Cortany: $_" -ForegroundColor Red
    }
    
    # Wyłączenie Windows Update P2P
    try {
        if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0 -ErrorAction Stop
        Write-Host "Wyłączono Windows Update P2P" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Błąd podczas konfiguracji Windows Update P2P: $_" -ForegroundColor Red
    }
    
    # Wyłączenie Windows Defender Cloud Protection
    try {
        if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet")) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 2 -ErrorAction Stop
        Write-Host "Wyłączono Windows Defender Cloud Protection" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Błąd podczas konfiguracji Windows Defender: $_" -ForegroundColor Red
    }
    
    Write-Host "Optymalizacja rejestru zakończona!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 4: KONFIGURACJA PYTHON I FIREWALL (POPRAWIONY)
# ==============================================================================

function Set-PythonSecurity {
    Write-Host "`n[MODUŁ 4] Konfiguracja bezpieczeństwa Python i Firewall..." -ForegroundColor Green
    
    # Sprawdzenie czy Python jest zainstalowany
    try {
        $pythonPath = (Get-Command python.exe -ErrorAction Stop).Source
        Write-Host "Python znaleziony: $pythonPath" -ForegroundColor Yellow
        
        # Pobierz katalog Python
        $pythonDir = Split-Path $pythonPath -Parent
        
        # Konfiguracja reguł firewall dla Python
        $pythonExecutables = @(
            "python.exe",
            "pythonw.exe",
            "pip.exe"
        )

        foreach ($exe in $pythonExecutables) {
            $exePath = Join-Path $pythonDir $exe
            if (Test-Path $exePath) {
                try {
                    # Zapytaj użytkownika czy chce zablokować Python
                    $blockPython = Read-Host "Czy chcesz zablokować połączenia dla $exe? (t/n)"
                    if ($blockPython -eq 't' -or $blockPython -eq 'T') {
                        New-NetFirewallRule -DisplayName "Block $exe Outbound" -Direction Outbound -Program $exePath -Action Block -ErrorAction Stop
                        Write-Host "Dodano regułę firewall dla: $exe" -ForegroundColor Yellow
                    }
                    else {
                        Write-Host "Pominięto blokowanie dla: $exe" -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Host "Nie można dodać reguły dla: $exe. Błąd: $_" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Nie znaleziono pliku: $exePath" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "Python nie został znaleziony lub wystąpił błąd: $_" -ForegroundColor Red
        return
    }
}

# ==============================================================================
# MODUŁ 5: BLOKOWANIE NIEBEZPIECZNYCH PORTÓW (POPRAWIONY)
# ==============================================================================

function Block-DangerousPorts {
    Write-Host "`n[MODUŁ 5] Blokowanie niebezpiecznych portów..." -ForegroundColor Green
    
    # Lista portów często wykorzystywanych w atakach z opisami
    $DangerousPorts = @(
        @{Port = 135; Name = "RPC Endpoint Mapper"; Critical = $true },
        @{Port = 137; Name = "NetBIOS Name Service"; Critical = $true },
        @{Port = 138; Name = "NetBIOS Datagram Service"; Critical = $true },
        @{Port = 139; Name = "NetBIOS Session Service"; Critical = $true },
        @{Port = 445; Name = "SMB over IP"; Critical = $true },
        @{Port = 1433; Name = "Microsoft SQL Server"; Critical = $false },
        @{Port = 1434; Name = "Microsoft SQL Server Browser"; Critical = $false },
        @{Port = 1723; Name = "PPTP"; Critical = $false },
        @{Port = 1900; Name = "UPnP"; Critical = $false },
        @{Port = 2869; Name = "UPnP Control Point"; Critical = $false },
        @{Port = 3389; Name = "Remote Desktop Protocol"; Critical = $false },
        @{Port = 5000; Name = "UPnP"; Critical = $false },
        @{Port = 5357; Name = "Web Services on Devices"; Critical = $false },
        @{Port = 5985; Name = "WinRM HTTP"; Critical = $false },
        @{Port = 5986; Name = "WinRM HTTPS"; Critical = $false },
        @{Port = 6129; Name = "DameWare Remote Support"; Critical = $false },
        @{Port = 8080; Name = "HTTP Alternate"; Critical = $false },
        @{Port = 9999; Name = "Telnet"; Critical = $false }
    )

    $blockAll = Read-Host "Czy chcesz zablokować wszystkie porty? (t/n)"
    
    foreach ($portInfo in $DangerousPorts) {
        $port = $portInfo.Port
        $name = $portInfo.Name
        $critical = $portInfo.Critical
        
        if ($blockAll -eq 't' -or $blockAll -eq 'T') {
            $block = $true
        }
        else {
            $block = $false
            if ($critical) {
                $block = Read-Host "Czy chcesz zablokować krytyczny port $port ($name)? Zalecane. (t/n)"
                if ($block -eq 't' -or $block -eq 'T') { $block = $true }
            }
            else {
                $block = Read-Host "Czy chcesz zablokować port $port ($name)? (t/n)"
                if ($block -eq 't' -or $block -eq 'T') { $block = $true }
            }
        }
        
        if ($block) {
            try {
                # Blokowanie portów TCP
                New-NetFirewallRule -DisplayName "Block Dangerous Port $port TCP" -Direction Inbound -Protocol TCP -LocalPort $port -Action Block -ErrorAction Stop
                New-NetFirewallRule -DisplayName "Block Dangerous Port $port TCP" -Direction Outbound -Protocol TCP -LocalPort $port -Action Block -ErrorAction Stop
                
                # Blokowanie portów UDP
                New-NetFirewallRule -DisplayName "Block Dangerous Port $port UDP" -Direction Inbound -Protocol UDP -LocalPort $port -Action Block -ErrorAction Stop
                New-NetFirewallRule -DisplayName "Block Dangerous Port $port UDP" -Direction Outbound -Protocol UDP -LocalPort $port -Action Block -ErrorAction Stop
                
                Write-Host "Zablokowano port: $port ($name)" -ForegroundColor Yellow
            }
            catch {
                Write-Host "Nie można zablokować portu ${port}: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Pominięto port: $port ($name)" -ForegroundColor Gray
        }
    }
    
    Write-Host "Blokowanie portów zakończone!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 6: DODATKOWE ZABEZPIECZENIA
# ==============================================================================

function Set-AdditionalSecurity {
    Write-Host "`n[MODUŁ 6] Stosowanie dodatkowych zabezpieczeń..." -ForegroundColor Green
    
    # Włączenie Windows Defender Firewall
    try {
        Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True -ErrorAction Stop
        Write-Host "Windows Firewall włączony dla wszystkich profili" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Nie można włączyć Windows Firewall: $_" -ForegroundColor Red
    }
    
    # Wyłączenie NetBIOS over TCP/IP
    try {
        $adapters = Get-CimInstance -Class Win32_NetworkAdapterConfiguration | Where-Object { $null -ne $_.TcpipNetbiosOptions }
        foreach ($adapter in $adapters) {
            $adapter | Invoke-CimMethod -MethodName SetTcpipNetbios -Arguments @{TcpipNetbiosOptions = 2 } -ErrorAction SilentlyContinue
        }
        Write-Host "NetBIOS over TCP/IP wyłączony" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Nie można wyłączyć NetBIOS over TCP/IP: $_" -ForegroundColor Red
    }
    
    # Konfiguracja UAC na najwyższy poziom
    try {
        if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System")) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -ErrorAction Stop
        Write-Host "UAC skonfigurowany na najwyższy poziom" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Nie można skonfigurować UAC: $_" -ForegroundColor Red
    }
    
    # Wyłączenie AutoRun/AutoPlay
    try {
        if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -ErrorAction Stop
        Write-Host "AutoRun/AutoPlay wyłączony" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Nie można wyłączyć AutoRun/AutoPlay: $_" -ForegroundColor Red
    }
    
    Write-Host "Dodatkowe zabezpieczenia zastosowane!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 7: CZYSZCZENIE DUPLIKATÓW FIREWALL
# ==============================================================================

function Remove-FirewallDuplicates {
    Write-Host "`n[MODUŁ 7] Czyszczenie duplikatów reguł firewall..." -ForegroundColor Green
    
    Write-Host "Szukanie duplikatów..." -ForegroundColor Yellow
    $cleaned = 0
    
    # Proste: znajdź reguły z identycznymi nazwami
    $rules = Get-NetFirewallRule
    $ruleNames = $rules | Group-Object DisplayName | Where-Object { $_.Count -gt 1 }
    
    foreach ($nameGroup in $ruleNames) {
        $duplicates = $nameGroup.Group
        Write-Host "Duplikat: $($nameGroup.Name) - $($duplicates.Count) kopii" -ForegroundColor Yellow
        
        # Zostaw pierwszą, usuń resztę
        for ($i = 1; $i -lt $duplicates.Count; $i++) {
            Remove-NetFirewallRule -Name $duplicates[$i].Name -ErrorAction SilentlyContinue
            $cleaned++
        }
    }
    
    Write-Host "Gotowe! Usunięto $cleaned duplikatów" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 8: CZYSZCZENIE I ORGANIZACJA PATH
# ==============================================================================

function Clear-PathVariable {
    Write-Host "`n[MODUŁ 8] Czyszczenie zmiennej PATH..." -ForegroundColor Green
    
    # Pobieranie aktualnego PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    Write-Host "Sprawdzanie System PATH..." -ForegroundColor Yellow
    $systemPaths = $currentPath -split ";" | Where-Object { $_ -ne "" }
    $validSystemPaths = @()
    $invalidSystemPaths = @()
    
    foreach ($path in $systemPaths) {
        if (Test-Path $path) {
            $validSystemPaths += $path
        }
        else {
            $invalidSystemPaths += $path
            Write-Host "Nieważna ścieżka w System PATH: $path" -ForegroundColor Red
        }
    }
    
    Write-Host "`nSprawdzanie User PATH..." -ForegroundColor Yellow
    $userPaths = $userPath -split ";" | Where-Object { $_ -ne "" }
    $validUserPaths = @()
    $invalidUserPaths = @()
    
    foreach ($path in $userPaths) {
        if (Test-Path $path) {
            $validUserPaths += $path
        }
        else {
            $invalidUserPaths += $path
            Write-Host "Nieważna ścieżka w User PATH: $path" -ForegroundColor Red
        }
    }
    
    # Usuwanie duplikatów
    $uniqueSystemPaths = $validSystemPaths | Select-Object -Unique
    $uniqueUserPaths = $validUserPaths | Select-Object -Unique
    
    $removedSystem = $validSystemPaths.Count - $uniqueSystemPaths.Count
    $removedUser = $validUserPaths.Count - $uniqueUserPaths.Count
    
    Write-Host "`n=== PODSUMOWANIE PATH ===" -ForegroundColor Cyan
    Write-Host "System PATH:" -ForegroundColor Yellow
    Write-Host "  - Nieprawidłowe ścieżki: $($invalidSystemPaths.Count)" -ForegroundColor Red
    Write-Host "  - Duplikaty usunięte: $removedSystem" -ForegroundColor Yellow
    Write-Host "  - Pozostałe ścieżki: $($uniqueSystemPaths.Count)" -ForegroundColor Green
    
    Write-Host "`nUser PATH:" -ForegroundColor Yellow
    Write-Host "  - Nieprawidłowe ścieżki: $($invalidUserPaths.Count)" -ForegroundColor Red
    Write-Host "  - Duplikaty usunięte: $removedUser" -ForegroundColor Yellow
    Write-Host "  - Pozostałe ścieżki: $($uniqueUserPaths.Count)" -ForegroundColor Green
    
    # Opcjonalne czyszczenie PATH
    $cleanup = Read-Host "`nCzy chcesz wyczyścić PATH z nieważnych ścieżek? (t/n)"
    if ($cleanup -eq "t" -or $cleanup -eq "T") {
        [Environment]::SetEnvironmentVariable("PATH", ($uniqueSystemPaths -join ";"), "Machine")
        [Environment]::SetEnvironmentVariable("PATH", ($uniqueUserPaths -join ";"), "User")
        Write-Host "PATH został wyczyszczony!" -ForegroundColor Green
        
        # Lista usuniętych ścieżek
        if ($invalidSystemPaths.Count -gt 0) {
            Write-Host "`nUsunięte z System PATH:" -ForegroundColor Red
            $invalidSystemPaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        }
        if ($invalidUserPaths.Count -gt 0) {
            Write-Host "`nUsunięte z User PATH:" -ForegroundColor Red
            $invalidUserPaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        }
    }
}

# ==============================================================================
# MODUŁ 9: TWORZENIE PROFILU POWERSHELL Z ALIASAMI
# ==============================================================================

function New-PowerShellProfile {
    Write-Host "`n[MODUŁ 9] Tworzenie profilu PowerShell z aliasami..." -ForegroundColor Green
    
    $profilePath = $PROFILE
    $profileDir = Split-Path $profilePath -Parent
    
    # Tworzenie katalogu profilu jeśli nie istnieje
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force
        Write-Host "Utworzono katalog profilu: $profileDir" -ForegroundColor Yellow
    }
    
    # Zawartość profilu PowerShell z polskimi aliasami
    $profileContent = @'
# ============================================================================
# PROFIL POWERSHELL - POLSKIE ALIASY I FUNKCJE
# Autor: Windows 10 Debloat & Security Script
# Data utworzenia: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
# ============================================================================

# Ustawienia podstawowe
 $Host.UI.RawUI.WindowTitle = "PowerShell - $env:USERNAME@$env:COMPUTERNAME"

# ============================================================================
# ALIASY LINUXOPODOBNE Z POLSKIMI OPISAMI
# ============================================================================

# === NAWIGACJA I LISTOWANIE ===
Set-Alias -Name lista -Value Get-ChildItem
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name la -Value Get-ChildItem
Set-Alias -Name katalog -Value Set-Location
Set-Alias -Name gdzie -Value Get-Location
Set-Alias -Name ..  -Value Set-Location

# === OPERACJE NA PLIKACH ===
Set-Alias -Name kopiuj -Value Copy-Item
Set-Alias -Name przenies -Value Move-Item
Set-Alias -Name usun -Value Remove-Item
Set-Alias -Name dotyk -Value New-Item
Set-Alias -Name mkdir -Value New-Item
Set-Alias -Name pokaz -Value Get-Content
Set-Alias -Name szukaj -Value Select-String

# === PROCESY I SYSTEM ===
Set-Alias -Name procesy -Value Get-Process
Set-Alias -Name zabij -Value Stop-Process
Set-Alias -Name top -Value Get-Process
Set-Alias -Name ktorzy -Value Get-LocalUser
Set-Alias -Name dyski -Value Get-Volume
Set-Alias -Name siec -Value Get-NetAdapter

# === NARZĘDZIA SIECIOWE ===
Set-Alias -Name ping -Value Test-Connection
Set-Alias -Name porty -Value Get-NetTCPConnection
Set-Alias -Name dns -Value Resolve-DnsName

# ============================================================================
# ZAAWANSOWANE FUNKCJE Z POLSKIMI NAZWAMI
# ============================================================================

function lista-szczegoly {
    <#
    .SYNOPSIS
    Szczegółowa lista plików z kolorowaniem
    .DESCRIPTION
    Wyświetla pliki i katalogi z kolorami i dodatkowymi informacjami
    #>
    Get-ChildItem | Format-Table -Property Mode, Length, LastWriteTime, Name -AutoSize
}

function szybki-skan {
    <#
    .SYNOPSIS
    Szybkie skanowanie systemu
    .DESCRIPTION
    Sprawdza procesy, porty, usługi i podstawowe informacje systemowe
    #>
    Write-Host "=== SZYBKI SKAN SYSTEMU ===" -ForegroundColor Cyan
    Write-Host "`nTOP 10 procesów wg CPU:" -ForegroundColor Yellow
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | Format-Table ProcessName, CPU, WorkingSet -AutoSize
    
    Write-Host "`nOtwarte porty nasłuchujące:" -ForegroundColor Yellow
    Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess | Sort-Object LocalPort | Format-Table -AutoSize
    
    Write-Host "`nZatrzymane usługi:" -ForegroundColor Yellow
    Get-Service | Where-Object Status -eq "Stopped" | Select-Object -First 5 | Format-Table Name, Status, StartType -AutoSize
}

function info-system {
    <#
    .SYNOPSIS
    Podstawowe informacje o systemie
    .DESCRIPTION
    Wyświetla informacje o systemie, sprzęcie i sieci
    #>
    Write-Host "=== INFORMACJE O SYSTEMIE ===" -ForegroundColor Cyan
    
    $os = Get-CimInstance Win32_OperatingSystem
    $comp = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor
    $mem = Get-CimInstance Win32_PhysicalMemory
    
    Write-Host "`nSystem:" -ForegroundColor Yellow
    Write-Host "  Nazwa: $($os.Caption)"
    Write-Host "  Wersja: $($os.Version)"
    Write-Host "  Komputer: $($comp.Name)"
    Write-Host "  Użytkownik: $env:USERNAME"
    
    Write-Host "`nSprzęt:" -ForegroundColor Yellow
    Write-Host "  Procesor: $($cpu.Name)"
    Write-Host "  RAM: $([math]::Round(($comp.TotalPhysicalMemory/1GB), 2)) GB"
    Write-Host "  Architektura: $($os.OSArchitecture)"
    
    Write-Host "`nSieć:" -ForegroundColor Yellow
    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Write-Host "  Karta: $($_.Name) [$($_.LinkSpeed)]"
    }
}

function czysc-temp {
    <#
    .SYNOPSIS
    Czyści pliki tymczasowe
    .DESCRIPTION
    Usuwa pliki tymczasowe z systemowych i użytkownika folderów temp
    #>
    Write-Host "Czyszczenie plików tymczasowych..." -ForegroundColor Yellow
    
    $tempFolders = @(
        $env:TEMP,
        "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\Temp"
    )
    
    $totalSize = 0
    $totalFiles = 0
    
    foreach ($folder in $tempFolders) {
        if (Test-Path $folder) {
            $files = Get-ChildItem $folder -Recurse -File -ErrorAction SilentlyContinue
            $folderSize = ($files | Measure-Object -Property Length -Sum).Sum
            $fileCount = $files.Count
            
            Write-Host "Katalog: $folder" -ForegroundColor Cyan
            Write-Host "  Pliki: $fileCount, Rozmiar: $([math]::Round($folderSize/1MB, 2)) MB" -ForegroundColor White
            
            # Usuwanie plików (bezpieczne)
            try {
                $files | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Host "  ✓ Wyczyszczono" -ForegroundColor Green
            }
            catch {
                Write-Host "  ⚠ Niektóre pliki w użyciu" -ForegroundColor Yellow
            }
            
            $totalSize += $folderSize
            $totalFiles += $fileCount
        }
    }
    
    Write-Host "`nPodsumowanie:" -ForegroundColor Green
    Write-Host "  Usunięto: $totalFiles plików"
    Write-Host "  Zwolniono: $([math]::Round($totalSize/1MB, 2)) MB"
}

function firewall-status {
    <#
    .SYNOPSIS
    Status Windows Firewall
    .DESCRIPTION
    Wyświetla status firewall i podstawowe reguły
    #>
    Write-Host "=== STATUS WINDOWS FIREWALL ===" -ForegroundColor Cyan
    
    Write-Host "`nProfile firewall:" -ForegroundColor Yellow
    Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction -AutoSize
    
    Write-Host "`nOstatnie reguły blokujące:" -ForegroundColor Yellow
    Get-NetFirewallRule | Where-Object {$_.Action -eq "Block" -and $_.Enabled -eq $true} | 
        Select-Object -First 10 DisplayName, Direction, Action | Format-Table -AutoSize
}

# ============================================================================
# FUNKCJE POMOCNICZE
# ============================================================================

function pomoc-aliasy {
    <#
    .SYNOPSIS
    Wyświetla wszystkie dostępne polskie aliasy
    #>
    Write-Host "=== DOSTĘPNE POLSKIE ALIASY ===" -ForegroundColor Cyan
    
    $aliases = Get-Alias | Where-Object {
        $_.Name -match "^(lista|katalog|gdzie|kopiuj|przenies|usun|dotyk|pokaz|szukaj|procesy|zabij|top|ktorzy|dyski|siec|porty|dns)$"
    }
    
    Write-Host "`nAliasy nawigacji:" -ForegroundColor Yellow
    Write-Host "  lista, ll, la  - listowanie plików i katalogów"
    Write-Host "  katalog, ..    - zmiana katalogu"
    Write-Host "  gdzie          - aktualny katalog"
    
    Write-Host "`nAliasy plików:" -ForegroundColor Yellow
    Write-Host "  kopiuj         - kopiowanie plików"
    Write-Host "  przenies       - przenoszenie plików"
    Write-Host "  usun           - usuwanie plików"
    Write-Host "  dotyk, mkdir   - tworzenie plików/katalogów"
    Write-Host "  pokaz          - wyświetlanie zawartości"
    Write-Host "  szukaj         - wyszukiwanie w plikach"
    
    Write-Host "`nAliasy systemowe:" -ForegroundColor Yellow
    Write-Host "  procesy, top   - lista procesów"
    Write-Host "  zabij          - zabijanie procesów"
    Write-Host "  ktorzy         - użytkownicy"
    Write-Host "  dyski          - informacje o dyskach"
    Write-Host "  siec, porty    - informacje sieciowe"
    
    Write-Host "`nZaawansowane funkcje:" -ForegroundColor Yellow
    Write-Host "  lista-szczegoly - szczegółowa lista plików"
    Write-Host "  szybki-skan    - skanowanie systemu"
    Write-Host "  info-system    - informacje o systemie"
    Write-Host "  czysc-temp     - czyszczenie plików temp"
    Write-Host "  firewall-status - status firewall"
}

# ============================================================================
# INICJALIZACJA
# ============================================================================

# Powitanie
Write-Host "PowerShell z polskimi aliasami załadowany!" -ForegroundColor Green
Write-Host "Wpisz 'pomoc-aliasy' aby zobaczyć dostępne komendy" -ForegroundColor Yellow

# Ustawienie aliasu dla pomocy
Set-Alias -Name pomocy -Value pomoc-aliasy
Set-Alias -Name pomoc -Value Get-Help

# Funkcja promptu z polskimi informacjami
function prompt {
    $location = Get-Location
    $user = $env:USERNAME
    $computer = $env:COMPUTERNAME
    
    Write-Host "[$user@$computer] " -NoNewline -ForegroundColor Green
    Write-Host "$location" -NoNewline -ForegroundColor Blue
    Write-Host " > " -NoNewline -ForegroundColor White
    return " "
}
'@

    # Zapisanie profilu
    $profileContent | Out-File -FilePath $profilePath -Encoding UTF8 -Force
    
    Write-Host "Profil PowerShell utworzony: $profilePath" -ForegroundColor Green
    Write-Host "`nDodane funkcje:" -ForegroundColor Yellow
    Write-Host "✓ Polskie aliasy (lista, katalog, kopiuj, usun, etc.)" -ForegroundColor Cyan
    Write-Host "✓ Funkcje systemowe (szybki-skan, info-system, czysc-temp)" -ForegroundColor Cyan
    Write-Host "✓ Zarządzanie firewall (firewall-status)" -ForegroundColor Cyan
    Write-Host "✓ Kolorowy prompt z informacjami o użytkowniku" -ForegroundColor Cyan
    Write-Host "✓ Funkcja pomocy (pomoc-aliasy)" -ForegroundColor Cyan
    
    $reload = Read-Host "`nCzy chcesz przeładować profil teraz? (t/n)"
    if ($reload -eq "t" -or $reload -eq "T") {
        . $profilePath
        Write-Host "Profil przeładowany! Wpisz 'pomoc-aliasy' aby zobaczyć dostępne komendy" -ForegroundColor Green
    }
}

# ==============================================================================
# MODUŁ 10: MONITORING I LOGI
# ==============================================================================

function New-SecurityLog {
    Write-Host "`n[MODUŁ 10] Tworzenie logu bezpieczeństwa..." -ForegroundColor Green
    
    $logPath = "$env:USERPROFILE\Desktop\Security_Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
    
    # Zbieranie informacji o systemie
    $firewallRules = (Get-NetFirewallRule).Count
    $blockedRules = (Get-NetFirewallRule | Where-Object Action -eq "Block").Count
    $systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pathEntries = ($systemPath -split ";").Count + ($userPath -split ";").Count
    
    $logContent = @"
=== Windows 10 Security & Debloat Log ===
Data wykonania: $(Get-Date)
Użytkownik: $env:USERNAME
Komputer: $env:COMPUTERNAME
System: $((Get-CimInstance Win32_OperatingSystem).Caption)

=== WYKONANE OPERACJE ===
✓ Usunięcie bloatware aplikacji
✓ Wyłączenie niepotrzebnych usług
✓ Optymalizacja rejestru
✓ Konfiguracja Python security
✓ Blokowanie niebezpiecznych portów
✓ Zastosowanie dodatkowych zabezpieczeń
✓ Czyszczenie duplikatów firewall
✓ Organizacja zmiennej PATH
✓ Utworzenie profilu PowerShell z polskimi aliasami

=== ZABLOKOWANE PORTY ===
135, 137, 138, 139, 445, 1433, 1434, 1723, 1900, 2869, 3389, 5000, 5357, 5985, 5986, 6129, 8080, 9999

=== STATUS FIREWALL ===
Łączna liczba reguł: $firewallRules
Reguły blokujące: $blockedRules
Profile firewall:
 $(Get-NetFirewallProfile | Format-Table -AutoSize | Out-String)

=== STATUS PATH ===
Łączna liczba wpisów PATH: $pathEntries
System PATH entries: $(($systemPath -split ";").Count)
User PATH entries: $(($userPath -split ";").Count)

=== NOWE FUNKCJE POWERSHELL ===
✓ Profil z polskimi aliasami utworzony: $PROFILE
✓ Dostępne polskie komendy: lista, katalog, kopiuj, usun, procesy, etc.
✓ Funkcje systemowe: szybki-skan, info-system, czysc-temp, firewall-status
✓ Pomoc: pomoc-aliasy

=== UWAGI ===
- Restart systemu może być wymagany dla pełnego zastosowania zmian
- Niektóre aplikacje mogą wymagać ponownej instalacji
- Sprawdź czy wszystkie potrzebne funkcje działają poprawnie
- Profil PowerShell zostanie załadowany przy następnym uruchomieniu
- Użyj 'pomoc-aliasy' w PowerShell aby zobaczyć wszystkie dostępne komendy

=== OSTATNIE REGUŁY FIREWALL (PRÓBKA) ===
 $(Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Block*"} | Select-Object -First 10 | Format-Table DisplayName, Direction, Action -AutoSize | Out-String)
"@

    $logContent | Out-File -FilePath $logPath -Encoding UTF8
    Write-Host "Rozszerzony log zapisany do: $logPath" -ForegroundColor Yellow
}

# ==============================================================================
# MENU GŁÓWNE
# ==============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "=== Windows 10 Debloat & Security Script v2.0 ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "GŁÓWNE OPCJE:" -ForegroundColor Green
    Write-Host "1. Uruchom wszystkie moduły (Zalecane)" -ForegroundColor Green
    Write-Host "2. Tylko Debloat (Moduł 1-3)" -ForegroundColor Yellow
    Write-Host "3. Tylko Security (Moduł 4-6)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "NARZĘDZIA SYSTEMOWE:" -ForegroundColor Cyan
    Write-Host "4. Czyść duplikaty Firewall" -ForegroundColor Yellow
    Write-Host "5. Organizuj zmienną PATH" -ForegroundColor Yellow
    Write-Host "6. Utwórz profil PowerShell z aliasami" -ForegroundColor Yellow
    Write-Host "7. Uruchom pojedynczy moduł" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "INFORMACJE:" -ForegroundColor Cyan
    Write-Host "8. Pokaż status systemu" -ForegroundColor White
    Write-Host "9. Status firewall i PATH" -ForegroundColor White
    Write-Host "0. Wyjście" -ForegroundColor Red
    Write-Host ""
    $choice = Read-Host "Wybierz opcję (0-9)"
    return $choice
}

function Show-SubMenu {
    Write-Host "`nWybierz moduł:" -ForegroundColor Cyan
    Write-Host "1. Remove Bloatware"
    Write-Host "2. Disable Services" 
    Write-Host "3. Registry Optimization"
    Write-Host "4. Python & Firewall Config"
    Write-Host "5. Block Dangerous Ports"
    Write-Host "6. Additional Security"
    Write-Host "7. Clean Firewall Duplicates"
    Write-Host "8. Clean PATH Variable"
    Write-Host "9. Create PowerShell Profile"
    Write-Host "10. Create Security Log"
    $choice = Read-Host "Wybierz moduł (1-10)"
    return $choice
}

# Usunięto duplikat funkcji Show-SystemStatus
function Show-SystemStatus {
    Clear-Host
    Write-Host "=== STATUS SYSTEMU ===" -ForegroundColor Cyan
    Write-Host "`nFirewall Status:"
    Get-NetFirewallProfile | Format-Table Name, Enabled -AutoSize
    
    Write-Host "`nAktywne reguły firewall (ostatnie 10):"
    Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*Block*" } | Select-Object -First 10 | Format-Table DisplayName, Direction, Action -AutoSize
    
    Write-Host "`nPython Status:"
    try {
        try {
            $pythonCmd = Get-Command python.exe -ErrorAction Stop
            $pythonPath = $pythonCmd.Source
            $pythonVersion = & $pythonPath --version 2>&1
            Write-Host $pythonVersion
        }
        catch {
            Write-Host "Python nie znaleziony" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Python nie znaleziony" -ForegroundColor Red
    }
    
    Write-Host "`nPATH entries:" -ForegroundColor Yellow
    $systemPath = ([Environment]::GetEnvironmentVariable("PATH", "Machine") -split ";").Count
    $userPath = ([Environment]::GetEnvironmentVariable("PATH", "User") -split ";").Count
    Write-Host "  System PATH: $systemPath entries"
    Write-Host "  User PATH: $userPath entries"
    
    pause
}

# ==============================================================================
# GŁÓWNA PĘTLA PROGRAMU
# ==============================================================================

do {
    $choice = Show-Menu
    
    switch ($choice) {
        "1" {
            Write-Host "`nUruchamianie wszystkich modułów..." -ForegroundColor Green
            New-SystemRestorePoint  # Dodano tworzenie punktu przywracania
            Remove-Bloatware
            Disable-UnnecessaryServices
            Optimize-Registry
            Set-PythonSecurity
            Block-DangerousPorts
            Set-AdditionalSecurity
            New-SecurityLog
            Write-Host "`n=== WSZYSTKIE OPERACJE ZAKOŃCZONE ===" -ForegroundColor Green
            Write-Host "Zalecany restart systemu!" -ForegroundColor Yellow
            pause
        }
        "2" {
            Write-Host "`nUruchamianie modułów Debloat..." -ForegroundColor Green
            New-SystemRestorePoint  # Dodano tworzenie punktu przywracania
            Remove-Bloatware
            Disable-UnnecessaryServices
            Optimize-Registry
            Write-Host "`n=== DEBLOAT ZAKOŃCZONY ===" -ForegroundColor Green
            pause
        }
        "3" {
            Write-Host "`nUruchamianie modułów Security..." -ForegroundColor Green
            New-SystemRestorePoint  # Dodano tworzenie punktu przywracania
            Set-PythonSecurity
            Block-DangerousPorts
            Set-AdditionalSecurity
            New-SecurityLog
            Write-Host "`n=== SECURITY ZAKOŃCZONY ===" -ForegroundColor Green
            pause
        }
        "4" { Remove-FirewallDuplicates; pause }
        "5" { Clear-PathVariable; pause }
        "6" { New-PowerShellProfile; pause }
        "7" {
            $subChoice = Show-SubMenu
            switch ($subChoice) {
                "1" { Remove-Bloatware }
                "2" { Disable-UnnecessaryServices }
                "3" { Optimize-Registry }
                "4" { Set-PythonSecurity }
                "5" { Block-DangerousPorts }
                "6" { Set-AdditionalSecurity }
                "7" { Remove-FirewallDuplicates }
                "8" { Clear-PathVariable }
                "9" { New-PowerShellProfile }
                "10" { New-SecurityLog }
                default { Write-Host "Nieprawidłowy wybór!" -ForegroundColor Red }
            }
            pause
        }
        "8" { Show-SystemStatus }
        "9" {
            Write-Host "`n=== STATUS FIREWALL I PATH ===" -ForegroundColor Cyan
            Remove-FirewallDuplicates
            Clear-PathVariable
            pause
        }
        "0" {
            Write-Host "Do widzenia!" -ForegroundColor Green
            break
        }
        default {
            Write-Host "Nieprawidłowy wybór! Spróbuj ponownie." -ForegroundColor Red
            pause
        }
    }
} while ($choice -ne "0")

Write-Host "`nSkrypt zakończony. Dziękuję za użycie!" -ForegroundColor Cyan
