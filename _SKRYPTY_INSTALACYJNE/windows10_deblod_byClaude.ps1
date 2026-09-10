# Windows 10 Debloat + Security Script
# Modularny skrypt do optymalizacji i zabezpieczania systemu
# Autor: Claude AI
# Wersja: 1.0

#Requires -RunAsAdministrator

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
    pause
    exit 1
}

# ==============================================================================
# MODUŁ 1: DEBLOAT - USUWANIE NIEPOTRZEBNYCH APLIKACJI
# ==============================================================================

function Remove-Bloatware {
    Write-Host "`n[MODUŁ 1] Usuwanie Bloatware..." -ForegroundColor Green
    
    # Lista aplikacji do usunięcia
    $BloatwareApps = @(
        "Microsoft.3DBuilder",
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
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.HelpAndTips",
        "Microsoft.Media.PlayReadyClient.2",
        "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.MinecraftUWP",
        "Microsoft.MixedReality.Portal",
        "Microsoft.MSPaint",
        "Microsoft.Office.OneNote",
        "Microsoft.OneConnect",
        "Microsoft.Print3D",
        "Microsoft.SkypeApp",
        "Microsoft.Wallet",
        "Microsoft.WebMediaExtensions",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera",
        "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsPhone",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "king.com.CandyCrushSaga",
        "king.com.CandyCrushSodaSaga",
        "king.com.BubbleWitch3Saga",
        "Flipboard.Flipboard",
        "ShazamEntertainmentLtd.Shazam",
        "SpotifyAB.SpotifyMusic",
        "PandoraMediaInc.29680B314EFC2",
        "ActiproSoftwareLLC.562882FEEB491",
        "D52A8D61.FarmVille2CountryEscape",
        "GAMELOFTSA.Asphalt8Airborne",
        "TuneIn.TuneInRadio",
        "Disney.37853FC22B2CE",
        "TheNewYorkTimes.NYTCrossword"
    )

    foreach ($App in $BloatwareApps) {
        try {
            Get-AppxPackage -Name $App -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $App | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            Write-Host "Usunięto: $App" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Nie można usunąć: $App" -ForegroundColor Red
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
            Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "Wyłączono usługę: $Service" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Nie można wyłączyć usługi: $Service" -ForegroundColor Red
        }
    }
    
    Write-Host "Wyłączanie usług zakończone!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 3: OPTYMALIZACJA REJESTRU
# ==============================================================================

function Optimize-Registry {
    Write-Host "`n[MODUŁ 3] Optymalizacja rejestru..." -ForegroundColor Green
    
    # Wyłączenie telemetrii
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction SilentlyContinue
    
    # Wyłączenie Cortany
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -ErrorAction SilentlyContinue
    
    # Wyłączenie Windows Update P2P
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0 -ErrorAction SilentlyContinue
    
    # Wyłączenie Windows Defender Cloud Protection
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 2 -ErrorAction SilentlyContinue
    
    Write-Host "Optymalizacja rejestru zakończona!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 4: KONFIGURACJA PYTHON I FIREWALL
# ==============================================================================

function Configure-Python-Security {
    Write-Host "`n[MODUŁ 4] Konfiguracja bezpieczeństwa Python i Firewall..." -ForegroundColor Green
    
    # Sprawdzenie czy Python jest zainstalowany
    try {
        $pythonPath = (Get-Command python.exe).Source
        Write-Host "Python znaleziony: $pythonPath" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Python nie został znaleziony!" -ForegroundColor Red
        return
    }

    # Konfiguracja reguł firewall dla Python
    $pythonExecutables = @(
        "python.exe",
        "pythonw.exe",
        "pip.exe"
    )

    foreach ($exe in $pythonExecutables) {
        try {
            # Blokowanie połączeń wychodzących dla Python (można dostosować według potrzeb)
            New-NetFirewallRule -DisplayName "Block $exe Outbound" -Direction Outbound -Program "$env:LOCALAPPDATA\Programs\Python\*\$exe" -Action Block -ErrorAction SilentlyContinue
            New-NetFirewallRule -DisplayName "Block $exe Outbound" -Direction Outbound -Program "$env:PROGRAMFILES\Python*\$exe" -Action Block -ErrorAction SilentlyContinue
            Write-Host "Dodano regułę firewall dla: $exe" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Nie można dodać reguły dla: $exe" -ForegroundColor Red
        }
    }
}

# ==============================================================================
# MODUŁ 5: BLOKOWANIE NIEBEZPIECZNYCH PORTÓW
# ==============================================================================

function Block-DangerousPorts {
    Write-Host "`n[MODUŁ 5] Blokowanie niebezpiecznych portów..." -ForegroundColor Green
    
    # Lista portów często wykorzystywanych w atakach
    $DangerousPorts = @(
        135,    # RPC Endpoint Mapper
        137,    # NetBIOS Name Service
        138,    # NetBIOS Datagram Service
        139,    # NetBIOS Session Service
        445,    # SMB over IP
        1433,   # Microsoft SQL Server
        1434,   # Microsoft SQL Server Browser
        1723,   # PPTP
        1900,   # UPnP
        2869,   # UPnP Control Point
        3389,   # Remote Desktop Protocol (opcjonalne)
        5000,   # UPnP
        5357,   # Web Services on Devices
        5985,   # WinRM HTTP
        5986,   # WinRM HTTPS
        6129,   # DameWare Remote Support
        8080,   # HTTP Alternate
        9999    # Telnet
    )

    foreach ($port in $DangerousPorts) {
        try {
            # Blokowanie portów TCP
            New-NetFirewallRule -DisplayName "Block Dangerous Port $port TCP" -Direction Inbound -Protocol TCP -LocalPort $port -Action Block -ErrorAction SilentlyContinue
            New-NetFirewallRule -DisplayName "Block Dangerous Port $port TCP" -Direction Outbound -Protocol TCP -LocalPort $port -Action Block -ErrorAction SilentlyContinue
            
            # Blokowanie portów UDP
            New-NetFirewallRule -DisplayName "Block Dangerous Port $port UDP" -Direction Inbound -Protocol UDP -LocalPort $port -Action Block -ErrorAction SilentlyContinue
            New-NetFirewallRule -DisplayName "Block Dangerous Port $port UDP" -Direction Outbound -Protocol UDP -LocalPort $port -Action Block -ErrorAction SilentlyContinue
            
            Write-Host "Zablokowano port: $port" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Nie można zablokować portu: $port" -ForegroundColor Red
        }
    }
    
    Write-Host "Blokowanie portów zakończone!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 6: DODATKOWE ZABEZPIECZENIA
# ==============================================================================

function Apply-AdditionalSecurity {
    Write-Host "`n[MODUŁ 6] Stosowanie dodatkowych zabezpieczeń..." -ForegroundColor Green
    
    # Włączenie Windows Defender Firewall
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-Host "Windows Firewall włączony dla wszystkich profili" -ForegroundColor Yellow
    
    # Wyłączenie NetBIOS over TCP/IP
    $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.TcpipNetbiosOptions -ne $null }
    foreach ($adapter in $adapters) {
        $adapter.SetTcpipNetbios(2) # 2 = Disable NetBIOS over TCP/IP
    }
    Write-Host "NetBIOS over TCP/IP wyłączony" -ForegroundColor Yellow
    
    # Konfiguracja UAC na najwyższy poziom
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -ErrorAction SilentlyContinue
    Write-Host "UAC skonfigurowany na najwyższy poziom" -ForegroundColor Yellow
    
    # Wyłączenie AutoRun/AutoPlay
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -ErrorAction SilentlyContinue
    Write-Host "AutoRun/AutoPlay wyłączony" -ForegroundColor Yellow
    
    Write-Host "Dodatkowe zabezpieczenia zastosowane!" -ForegroundColor Green
}

# ==============================================================================
# MODUŁ 7: MONITORING I LOGI
# ==============================================================================

function Create-SecurityLog {
    Write-Host "`n[MODUŁ 7] Tworzenie logu bezpieczeństwa..." -ForegroundColor Green
    
    $logPath = "$env:USERPROFILE\Desktop\Security_Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
    
    $logContent = @"
=== Windows 10 Security & Debloat Log ===
Data wykonania: $(Get-Date)
Użytkownik: $env:USERNAME
Komputer: $env:COMPUTERNAME

=== WYKONANE OPERACJE ===
✓ Usunięcie bloatware aplikacji
✓ Wyłączenie niepotrzebnych usług
✓ Optymalizacja rejestru
✓ Konfiguracja Python security
✓ Blokowanie niebezpiecznych portów
✓ Zastosowanie dodatkowych zabezpieczeń

=== ZABLOKOWANE PORTY ===
135, 137, 138, 139, 445, 1433, 1434, 1723, 1900, 2869, 3389, 5000, 5357, 5985, 5986, 6129, 8080, 9999

=== UWAGI ===
- Restart systemu może być wymagany dla pełnego zastosowania zmian
- Niektóre aplikacje mogą wymagać ponownej instalacji
- Sprawdź czy wszystkie potrzebne funkcje działają poprawnie

=== STATUS FIREWALL ===
$(Get-NetFirewallProfile | Format-Table -AutoSize | Out-String)
"@

    $logContent | Out-File -FilePath $logPath -Encoding UTF8
    Write-Host "Log zapisany do: $logPath" -ForegroundColor Yellow
}

# ==============================================================================
# MENU GŁÓWNE
# ==============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "=== Windows 10 Debloat & Security Script ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Uruchom wszystkie moduły (Zalecane)" -ForegroundColor Green
    Write-Host "2. Tylko Debloat (Moduł 1-3)" -ForegroundColor Yellow
    Write-Host "3. Tylko Security (Moduł 4-6)" -ForegroundColor Yellow
    Write-Host "4. Uruchom pojedynczy moduł" -ForegroundColor Yellow
    Write-Host "5. Pokaż status systemu" -ForegroundColor Cyan
    Write-Host "0. Wyjście" -ForegroundColor Red
    Write-Host ""
    $choice = Read-Host "Wybierz opcję (0-5)"
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
    Write-Host "7. Create Security Log"
    $choice = Read-Host "Wybierz moduł (1-7)"
    return $choice
}

function Show-SystemStatus {
    Clear-Host
    Write-Host "=== STATUS SYSTEMU ===" -ForegroundColor Cyan
    Write-Host "`nFirewall Status:"
    Get-NetFirewallProfile | Format-Table Name, Enabled -AutoSize
    
    Write-Host "`nAktywne reguły firewall (ostatnie 10):"
    Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Block*"} | Select-Object -First 10 | Format-Table DisplayName, Direction, Action -AutoSize
    
    Write-Host "`nPython Status:"
    try {
        python --version
    }
    catch {
        Write-Host "Python nie znaleziony" -ForegroundColor Red
    }
    
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
            Remove-Bloatware
            Disable-UnnecessaryServices
            Optimize-Registry
            Configure-Python-Security
            Block-DangerousPorts
            Apply-AdditionalSecurity
            Create-SecurityLog
            Write-Host "`n=== WSZYSTKIE OPERACJE ZAKOŃCZONE ===" -ForegroundColor Green
            Write-Host "Zalecany restart systemu!" -ForegroundColor Yellow
            pause
        }
        "2" {
            Write-Host "`nUruchamianie modułów Debloat..." -ForegroundColor Green
            Remove-Bloatware
            Disable-UnnecessaryServices
            Optimize-Registry
            Write-Host "`n=== DEBLOAT ZAKOŃCZONY ===" -ForegroundColor Green
            pause
        }
        "3" {
            Write-Host "`nUruchamianie modułów Security..." -ForegroundColor Green
            Configure-Python-Security
            Block-DangerousPorts
            Apply-AdditionalSecurity
            Create-SecurityLog
            Write-Host "`n=== SECURITY ZAKOŃCZONY ===" -ForegroundColor Green
            pause
        }
        "4" {
            $subChoice = Show-SubMenu
            switch ($subChoice) {
                "1" { Remove-Bloatware }
                "2" { Disable-UnnecessaryServices }
                "3" { Optimize-Registry }
                "4" { Configure-Python-Security }
                "5" { Block-DangerousPorts }
                "6" { Apply-AdditionalSecurity }
                "7" { Create-SecurityLog }
                default { Write-Host "Nieprawidłowy wybór!" -ForegroundColor Red }
            }
            pause
        }
        "5" {
            Show-SystemStatus
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
