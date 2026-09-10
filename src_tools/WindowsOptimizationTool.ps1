# ==============================================================================
# Windows Optimization & Security Tool - GUI Version
# Autor: Claude AI
# Wersja: 2.0
# ==============================================================================

# Import wymaganych modułów
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# Sprawdzenie uprawnień administratora
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    [System.Windows.MessageBox]::Show("Ten program musi być uruchomiony jako Administrator!", "Błąd", "OK", "Error")
    exit 1
}

# ==============================================================================
# GŁÓWNE OKNO APLIKACJI
# ==============================================================================

 $mainForm = New-Object System.Windows.Forms.Form
 $mainForm.Text = "Windows Optimization & Security Tool v2.0"
 $mainForm.Size = New-Object System.Drawing.Size(1200, 800)
 $mainForm.StartPosition = "CenterScreen"
 $mainForm.FormBorderStyle = "FixedDialog"
 $mainForm.MaximizeBox = $false
 $mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")

# ==============================================================================
# KONTROLKI GŁÓWNE
# ==============================================================================

# Panel górny z tytułem
 $titlePanel = New-Object System.Windows.Forms.Panel
 $titlePanel.Dock = "Top"
 $titlePanel.Height = 60
 $titlePanel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
 $mainForm.Controls.Add($titlePanel)

 $titleLabel = New-Object System.Windows.Forms.Label
 $titleLabel.Text = "Windows Optimization & Security Tool"
 $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
 $titleLabel.ForeColor = [System.Drawing.Color]::White
 $titleLabel.AutoSize = $true
 $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
 $titlePanel.Controls.Add($titleLabel)

 $subtitleLabel = New-Object System.Windows.Forms.Label
 $subtitleLabel.Text = "Narzędzie do optymalizacji i zabezpieczania systemu Windows"
 $subtitleLabel.Font = New-Object System.Windows.Font("Segoe UI", 10)
 $subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
 $subtitleLabel.AutoSize = $true
 $subtitleLabel.Location = New-Object System.Drawing.Point(20, 40)
 $titlePanel.Controls.Add($subtitleLabel)

# Panel dolny z przyciskami
 $bottomPanel = New-Object System.Windows.Forms.Panel
 $bottomPanel.Dock = "Bottom"
 $bottomPanel.Height = 80
 $bottomPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
 $mainForm.Controls.Add($bottomPanel)

# Przyciski akcji
 $runButton = New-Object System.Windows.Forms.Button
 $runButton.Text = "Uruchom wybrane operacje"
 $runButton.Size = New-Object System.Drawing.Size(200, 40)
 $runButton.Location = New-Object System.Drawing.Point(20, 20)
 $runButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
 $runButton.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
 $runButton.ForeColor = [System.Drawing.Color]::White
 $runButton.Cursor = [System.Windows.Forms.Cursors]::Hand
 $bottomPanel.Controls.Add($runButton)

 $selectAllButton = New-Object System.Windows.Forms.Button
 $selectAllButton.Text = "Zaznacz wszystko"
 $selectAllButton.Size = New-Object System.Drawing.Size(150, 40)
 $selectAllButton.Location = New-Object System.Drawing.Point(240, 20)
 $selectAllButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
 $selectAllButton.BackColor = [System.Drawing.Color]::FromArgb(33, 150, 243)
 $selectAllButton.ForeColor = [System.Drawing.Color]::White
 $selectAllButton.Cursor = [System.Windows.Forms.Cursors]::Hand
 $bottomPanel.Controls.Add($selectAllButton)

 $clearAllButton = New-Object System.Windows.Forms.Button
 $clearAllButton.Text = "Odznacz wszystko"
 $clearAllButton.Size = New-Object System.Drawing.Size(150, 40)
 $clearAllButton.Location = New-Object System.Drawing.Point(410, 20)
 $clearAllButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
 $clearAllButton.BackColor = [System.Drawing.Color]::FromArgb(244, 67, 54)
 $clearAllButton.ForeColor = [System.Drawing.Color]::White
 $clearAllButton.Cursor = [System.Windows.Forms.Cursors]::Hand
 $bottomPanel.Controls.Add($clearAllButton)

# Panel centralny z zakładkami
 $tabControl = New-Object System.Windows.Forms.TabControl
 $tabControl.Dock = "Fill"
 $tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
 $mainForm.Controls.Add($tabControl)

# ==============================================================================
# ZAKŁADKA 1: DEBLOAT
# ==============================================================================

 $debloatTab = New-Object System.Windows.Forms.TabPage
 $debloatTab.Text = "Debloat"
 $debloatTab.BackColor = [System.Drawing.Color]::White
 $tabControl.Controls.Add($debloatTab)

# Panel dla aplikacji bloatware
 $bloatwarePanel = New-Object System.Windows.Forms.Panel
 $bloatwarePanel.Location = New-Object System.Drawing.Point(20, 20)
 $bloatwarePanel.Size = New-Object System.Drawing.Size(550, 600)
 $bloatwarePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
 $debloatTab.Controls.Add($bloatwarePanel)

 $bloatwareLabel = New-Object System.Windows.Forms.Label
 $bloatwareLabel.Text = "Aplikacje Bloatware"
 $bloatwareLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
 $bloatwareLabel.Location = New-Object System.Drawing.Point(10, 10)
 $bloatwareLabel.AutoSize = $true
 $bloatwarePanel.Controls.Add($bloatwareLabel)

# Lista aplikacji bloatware z kategoriami
 $bloatwareCategories = @{
    "Gry" = @(
        "king.com.CandyCrushSaga",
        "king.com.CandyCrushSodaSaga",
        "king.com.BubbleWitch3Saga",
        "Microsoft.MinecraftUWP",
        "GAMELOFTSA.Asphalt8Airborne"
    )
    "Multimedia" = @(
        "SpotifyAB.SpotifyMusic",
        "PandoraMediaInc.29680B314EFC2",
        "ShazamEntertainmentLtd.Shazam",
        "TuneIn.TuneInRadio",
        "Flipboard.Flipboard"
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
        "Microsoft.Print3D"
    )
    "Xbox" = @(
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider"
    )
}

 $checkboxes = @{}
 $yPos = 50

foreach ($category in $bloatwareCategories.Keys) {
    $categoryLabel = New-Object System.Windows.Forms.Label
    $categoryLabel.Text = $category
    $categoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $categoryLabel.Location = New-Object System.Drawing.Point(10, $yPos)
    $categoryLabel.ForeColor = [System.Drawing.Color]::FromArgb(33, 150, 243)
    $categoryLabel.AutoSize = $true
    $bloatwarePanel.Controls.Add($categoryLabel)
    
    $yPos += 30
    
    foreach ($app in $bloatwareCategories[$category]) {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Text = $app
        $checkbox.Location = New-Object System.Drawing.Point(30, $yPos)
        $checkbox.AutoSize = $true
        $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $bloatwarePanel.Controls.Add($checkbox)
        $checkboxes[$app] = $checkbox
        $yPos += 25
    }
    
    $yPos += 10
}

# Panel dla usług
 $servicesPanel = New-Object System.Windows.Forms.Panel
 $servicesPanel.Location = New-Object System.Drawing.Point(590, 20)
 $servicesPanel.Size = New-Object System.Drawing.Size(550, 600)
 $servicesPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
 $debloatTab.Controls.Add($servicesPanel)

 $servicesLabel = New-Object System.Windows.Forms.Label
 $servicesLabel.Text = "Usługi do wyłączenia"
 $servicesLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
 $servicesLabel.Location = New-Object System.Drawing.Point(10, 10)
 $servicesLabel.AutoSize = $true
 $servicesPanel.Controls.Add($servicesLabel)

# Lista usług
 $servicesList = @(
    "DiagTrack",                # Connected User Experiences and Telemetry
    "dmwappushservice",         # WAP Push Message Routing Service
    "HomeGroupListener",        # HomeGroup Listener
    "HomeGroupProvider",        # HomeGroup Provider
    "lfsvc",                   # Geolocation Service
    "MapsBroker",              # Downloaded Maps Manager
    "RemoteRegistry",          # Remote Registry
    "SharedAccess",            # Internet Connection Sharing (ICS)
    "XblAuthManager",          # Xbox Live Auth Manager
    "XblGameSave",             # Xbox Live Game Save Service
    "XboxNetApiSvc"            # Xbox Live Networking Service
)

 $serviceCheckboxes = @{}
 $yPos = 50

foreach ($service in $servicesList) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $service
    $checkbox.Location = New-Object System.Drawing.Point(10, $yPos)
    $checkbox.AutoSize = $true
    $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $servicesPanel.Controls.Add($checkbox)
    $serviceCheckboxes[$service] = $checkbox
    $yPos += 25
}

# ==============================================================================
# ZAKŁADKA 2: SECURITY
# ==============================================================================

 $securityTab = New-Object System.Windows.Forms.TabPage
 $securityTab.Text = "Security"
 $securityTab.BackColor = [System.Drawing.Color]::White
 $tabControl.Controls.Add($securityTab)

# Panel dla portów
 $portsPanel = New-Object System.Windows.Forms.Panel
 $portsPanel.Location = New-Object System.Drawing.Point(20, 20)
 $portsPanel.Size = New-Object System.Drawing.Size(550, 600)
 $portsPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
 $securityTab.Controls.Add($portsPanel)

 $portsLabel = New-Object System.Windows.Forms.Label
 $portsLabel.Text = "Niebezpieczne porty do zablokowania"
 $portsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
 $portsLabel.Location = New-Object System.Drawing.Point(10, 10)
 $portsLabel.AutoSize = $true
 $portsPanel.Controls.Add($portsLabel)

# Lista portów
 $portsList = @(
    @{Port = 135; Name = "RPC Endpoint Mapper"; Critical = $true},
    @{Port = 137; Name = "NetBIOS Name Service"; Critical = $true},
    @{Port = 138; Name = "NetBIOS Datagram Service"; Critical = $true},
    @{Port = 139; Name = "NetBIOS Session Service"; Critical = $true},
    @{Port = 445; Name = "SMB over IP"; Critical = $true},
    @{Port = 1433; Name = "Microsoft SQL Server"; Critical = $false},
    @{Port = 1434; Name = "Microsoft SQL Server Browser"; Critical = $false},
    @{Port = 1723; Name = "PPTP"; Critical = $false},
    @{Port = 1900; Name = "UPnP"; Critical = $false},
    @{Port = 2869; Name = "UPnP Control Point"; Critical = $false},
    @{Port = 3389; Name = "Remote Desktop Protocol"; Critical = $false},
    @{Port = 5985; Name = "WinRM HTTP"; Critical = $false},
    @{Port = 5986; Name = "WinRM HTTPS"; Critical = $false}
)

 $portCheckboxes = @{}
 $yPos = 50

foreach ($portInfo in $portsList) {
    $port = $portInfo.Port
    $name = $portInfo.Name
    $critical = $portInfo.Critical
    
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = "$port - $name"
    if ($critical) {
        $checkbox.Checked = $true
        $checkbox.ForeColor = [System.Drawing.Color]::FromArgb(244, 67, 54)
    }
    $checkbox.Location = New-Object System.Drawing.Point(10, $yPos)
    $checkbox.AutoSize = $true
    $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $portsPanel.Controls.Add($checkbox)
    $portCheckboxes[$port] = $checkbox
    $yPos += 25
}

# Panel dla ustawień bezpieczeństwa
 $securitySettingsPanel = New-Object System.Windows.Forms.Panel
 $securitySettingsPanel.Location = New-Object System.Drawing.Point(590, 20)
 $securitySettingsPanel.Size = New-Object System.Drawing.Size(550, 600)
 $securitySettingsPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
 $securityTab.Controls.Add($securitySettingsPanel)

 $securitySettingsLabel = New-Object System.Windows.Forms.Label
 $securitySettingsLabel.Text = "Ustawienia bezpieczeństwa"
 $securitySettingsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
 $securitySettingsLabel.Location = New-Object System.Drawing.Point(10, 10)
 $securitySettingsLabel.AutoSize = $true
 $securitySettingsPanel.Controls.Add($securitySettingsLabel)

# Ustawienia bezpieczeństwa
 $securitySettings = @(
    @{Name = "Wyłącz telemetrię"; Key = "Telemetry"},
    @{Name = "Wyłącz Cortanę"; Key = "Cortana"},
    @{Name = "Włącz Windows Firewall"; Key = "Firewall"},
    @{Name = "Wyłącz NetBIOS over TCP/IP"; Key = "NetBIOS"},
    @{Name = "Ustaw UAC na najwyższy poziom"; Key = "UAC"},
    @{Name = "Wyłącz AutoRun/AutoPlay"; Key = "AutoRun"},
    @{Name = "Wyłącz Windows Update P2P"; Key = "UpdateP2P"}
)

 $securityCheckboxes = @{}
 $yPos = 50

foreach ($setting in $securitySettings) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $setting.Name
    $checkbox.Checked = $true
    $checkbox.Location = New-Object System.Drawing.Point(10, $yPos)
    $checkbox.AutoSize = $true
    $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $securitySettingsPanel.Controls.Add($checkbox)
    $securityCheckboxes[$setting.Key] = $checkbox
    $yPos += 30
}

# ==============================================================================
# ZAKŁADKA 3: SYSTEM
# ==============================================================================

 $systemTab = New-Object System.Windows.Forms.TabPage
 $systemTab.Text = "System"
 $systemTab.BackColor = [System.Drawing.Color]::White
 $tabControl.Controls.Add($systemTab)

# Panel dla narzędzi systemowych
 $systemToolsPanel = New-Object System.Windows.Forms.Panel
 $systemToolsPanel.Location = New-Object System.Drawing.Point(20, 20)
 $systemToolsPanel.Size = New-Object System.Drawing.Size(550, 600)
 $systemToolsPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
 $systemTab.Controls.Add($systemToolsPanel)

 $systemToolsLabel = New-Object System.Windows.Forms.Label
 $systemToolsLabel.Text = "Narzędzia systemowe"
 $systemToolsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
 $systemToolsLabel.Location = New-Object System.Drawing.Point(10, 10)
 $systemToolsLabel.AutoSize = $true
 $systemToolsPanel.Controls.Add($systemToolsLabel)

# Lista narzędzi systemowych
 $systemTools = @(
    @{Name = "Utwórz punkt przywracania"; Key = "RestorePoint"},
    @{Name = "Wyczyść zmiennej PATH"; Key = "CleanPATH"},
    @{Name = "Wyczyść duplikaty firewall"; Key = "CleanFirewall"},
    @{Name = "Utwórz profil PowerShell"; Key = "PowerShellProfile"},
    @{Name = "Wyczyść pliki tymczasowe"; Key = "CleanTemp"},
    @{Name = "Stwórz log bezpieczeństwa"; Key = "SecurityLog"}
)

 $systemToolCheckboxes = @{}
 $yPos = 50

foreach ($tool in $systemTools) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $tool.Name
    $checkbox.Location = New-Object System.Drawing.Point(10, $yPos)
    $checkbox.AutoSize = $true
    $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $systemToolsPanel.Controls.Add($checkbox)
    $systemToolCheckboxes[$tool.Key] = $checkbox
    $yPos += 30
}

# Panel statusu systemu
 $systemStatusPanel = New-Object System.Windows.Forms.Panel
 $systemStatusPanel.Location = New-Object System.Drawing.Point(590, 20)
 $systemStatusPanel.Size = New-Object System.Drawing.Size(550, 600)
 $systemStatusPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
 $systemTab.Controls.Add($systemStatusPanel)

 $systemStatusLabel = New-Object System.Windows.Forms.Label
 $systemStatusLabel.Text = "Status systemu"
 $systemStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
 $systemStatusLabel.Location = New-Object System.Drawing.Point(10, 10)
 $systemStatusLabel.AutoSize = $true
 $systemStatusPanel.Controls.Add($systemStatusLabel)

# Przycisk odświeżania statusu
 $refreshStatusButton = New-Object System.Windows.Forms.Button
 $refreshStatusButton.Text = "Odśwież status"
 $refreshStatusButton.Size = New-Object System.Drawing.Size(150, 30)
 $refreshStatusButton.Location = New-Object System.Drawing.Point(10, 50)
 $refreshStatusButton.BackColor = [System.Drawing.Color]::FromArgb(33, 150, 243)
 $refreshStatusButton.ForeColor = [System.Drawing.Color]::White
 $refreshStatusButton.Cursor = [System.Windows.Forms.Cursors]::Hand
 $systemStatusPanel.Controls.Add($refreshStatusButton)

# Pole tekstowe dla statusu
 $statusTextBox = New-Object System.Windows.Forms.TextBox
 $statusTextBox.Multiline = $true
 $statusTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
 $statusTextBox.Location = New-Object System.Drawing.Point(10, 90)
 $statusTextBox.Size = New-Object System.Drawing.Size(520, 480)
 $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
 $statusTextBox.ReadOnly = $true
 $statusTextBox.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
 $systemStatusPanel.Controls.Add($statusTextBox)

# ==============================================================================
# ZAKŁADKA 4: LOGI
# ==============================================================================

 $logsTab = New-Object System.Windows.Forms.TabPage
 $logsTab.Text = "Logi"
 $logsTab.BackColor = [System.Drawing.Color]::White
 $tabControl.Controls.Add($logsTab)

# Panel logów
 $logsPanel = New-Object System.Windows.Forms.Panel
 $logsPanel.Dock = "Fill"
 $logsPanel.Padding = New-Object System.Windows.Forms.Padding(20)
 $logsTab.Controls.Add($logsPanel)

 $logsLabel = New-Object System.Windows.Forms.Label
 $logsLabel.Text = "Log operacji"
 $logsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
 $logsLabel.Location = New-Object System.Drawing.Point(0, 0)
 $logsLabel.AutoSize = $true
 $logsPanel.Controls.Add($logsLabel)

# Pole tekstowe dla logów
 $logTextBox = New-Object System.Windows.Forms.TextBox
 $logTextBox.Multiline = $true
 $logTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
 $logTextBox.Location = New-Object System.Drawing.Point(0, 40)
 $logTextBox.Size = New-Object System.Drawing.Size(1120, 680)
 $logTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
 $logTextBox.ReadOnly = $true
 $logTextBox.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
 $logsPanel.Controls.Add($logTextBox)

# Przyciski dla logów
 $clearLogsButton = New-Object System.Windows.Forms.Button
 $clearLogsButton.Text = "Wyczyść logi"
 $clearLogsButton.Size = New-Object System.Drawing.Size(120, 30)
 $clearLogsButton.Location = New-Object System.Drawing.Point(0, 730)
 $clearLogsButton.BackColor = [System.Drawing.Color]::FromArgb(244, 67, 54)
 $clearLogsButton.ForeColor = [System.Drawing.Color]::White
 $clearLogsButton.Cursor = [System.Windows.Forms.Cursors]::Hand
 $logsPanel.Controls.Add($clearLogsButton)

 $saveLogsButton = New-Object System.Windows.Forms.Button
 $saveLogsButton.Text = "Zapisz logi"
 $saveLogsButton.Size = New-Object System.Drawing.Size(120, 30)
 $saveLogsButton.Location = New-Object System.Drawing.Point(130, 730)
 $saveLogsButton.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
 $saveLogsButton.ForeColor = [System.Drawing.Color]::White
 $saveLogsButton.Cursor = [System.Windows.Forms.Cursors]::Hand
 $logsPanel.Controls.Add($saveLogsButton)

# ==============================================================================
# FUNKCJE POMOCNICZE
# ==============================================================================

# Funkcja logowania
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Dodaj do pola tekstowego
    if ($logTextBox.InvokeRequired) {
        $logTextBox.Invoke([System.Action[string]]{
            param($text)
            $logTextBox.AppendText($text + "`r`n")
            $logTextBox.ScrollToCaret()
        }, $logEntry)
    } else {
        $logTextBox.AppendText($logEntry + "`r`n")
        $logTextBox.ScrollToCaret()
    }
    
    # Zapisz do pliku
    $logFile = "$env:USERPROFILE\Desktop\WindowsOptimizationLog_$(Get-Date -Format 'yyyyMMdd').txt"
    Add-Content -Path $logFile -Value $logEntry
}

# Funkcja tworzenia punktu przywracania
function Create-RestorePoint {
    Write-Log "Tworzenie punktu przywracania systemu..."
    
    try {
        # Sprawdź czy usługa jest włączona
        $restoreService = Get-Service -Name "srservice" -ErrorAction SilentlyContinue
        if (-not $restoreService -or $restoreService.Status -ne "Running") {
            Write-Log "Włączanie usługi przywracania systemu..."
            Enable-ComputerRestore -Drive "$env:SystemDrive"
            Start-Service -Name "srservice" -ErrorAction SilentlyContinue
        }
        
        # Utwórz punkt przywracania
        Checkpoint-Computer -Description "Windows Optimization Tool" -RestorePointType "MODIFY_SETTINGS"
        Write-Log "Punkt przywracania utworzony pomyślnie!" "SUCCESS"
    }
    catch {
        Write-Log "Nie można utworzyć punktu przywracania: $_" "ERROR"
    }
}

# Funkcja usuwania aplikacji bloatware
function Remove-BloatwareApps {
    param (
        [array]$AppsToRemove
    )
    
    Write-Log "Usuwanie aplikacji bloatware..."
    
    foreach ($app in $AppsToRemove) {
        try {
            $appPackage = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
            $provisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app -ErrorAction SilentlyContinue
            
            if ($appPackage -or $provisionedPackage) {
                $appPackage | Remove-AppxPackage -ErrorAction SilentlyContinue
                $provisionedPackage | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                Write-Log "Usunięto: $app" "SUCCESS"
            } else {
                Write-Log "Nie znaleziono: $app" "WARNING"
            }
        }
        catch {
            Write-Log "Nie można usunąć: $app. Błąd: $_" "ERROR"
        }
    }
}

# Funkcja wyłączania usług
function Disable-Services {
    param (
        [array]$ServicesToDisable
    )
    
    Write-Log "Wyłączanie usług..."
    
    foreach ($service in $ServicesToDisable) {
        try {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Log "Wyłączono usługę: $service" "SUCCESS"
            } else {
                Write-Log "Usługa nie istnieje: $service" "WARNING"
            }
        }
        catch {
            Write-Log "Nie można wyłączyć usługi: $service. Błąd: $_" "ERROR"
        }
    }
}

# Funkcja blokowania portów
function Block-DangerousPorts {
    param (
        [array]$PortsToBlock
    )
    
    Write-Log "Blokowanie niebezpiecznych portów..."
    
    foreach ($port in $PortsToBlock) {
        try {
            # Blokowanie portów TCP
            New-NetFirewallRule -DisplayName "Block Dangerous Port $port TCP" -Direction Inbound -Protocol TCP -LocalPort $port -Action Block -ErrorAction Stop
            New-NetFirewallRule -DisplayName "Block Dangerous Port $port TCP" -Direction Outbound -Protocol TCP -LocalPort $port -Action Block -ErrorAction Stop
            
            # Blokowanie portów UDP
            New-NetFirewallRule -DisplayName "Block Dangerous Port $port UDP" -Direction Inbound -Protocol UDP -LocalPort $port -Action Block -ErrorAction Stop
            New-NetFirewallRule -DisplayName "Block Dangerous Port $port UDP" -Direction Outbound -Protocol UDP -LocalPort $port -Action Block -ErrorAction Stop
            
            Write-Log "Zablokowano port: $port" "SUCCESS"
        }
        catch {
            Write-Log "Nie można zablokować portu ${port}: $_" "ERROR"
        }
    }
}

# Funkcja konfiguracji ustawień bezpieczeństwa
function Configure-SecuritySettings {
    param (
        [hashtable]$Settings
    )
    
    Write-Log "Konfiguracja ustawień bezpieczeństwa..."
    
    # Wyłączenie telemetrii
    if ($Settings["Telemetry"]) {
        try {
            if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection")) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction Stop
            
            if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")) {
                New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction Stop
            Write-Log "Wyłączono telemetrię" "SUCCESS"
        }
        catch {
            Write-Log "Błąd podczas konfiguracji telemetrii: $_" "ERROR"
        }
    }
    
    # Wyłączenie Cortany
    if ($Settings["Cortana"]) {
        try {
            if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
                New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -ErrorAction Stop
            Write-Log "Wyłączono Cortanę" "SUCCESS"
        }
        catch {
            Write-Log "Błąd podczas wyłączania Cortany: $_" "ERROR"
        }
    }
    
    # Włączenie Windows Firewall
    if ($Settings["Firewall"]) {
        try {
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction Stop
            Write-Log "Windows Firewall włączony dla wszystkich profili" "SUCCESS"
        }
        catch {
            Write-Log "Nie można włączyć Windows Firewall: $_" "ERROR"
        }
    }
    
    # Wyłączenie NetBIOS over TCP/IP
    if ($Settings["NetBIOS"]) {
        try {
            $adapters = Get-CimInstance -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.TcpipNetbiosOptions -ne $null }
            foreach ($adapter in $adapters) {
                $adapter | Invoke-CimMethod -MethodName SetTcpipNetbios -Arguments @{TcpipNetbiosOptions = 2} -ErrorAction SilentlyContinue
            }
            Write-Log "NetBIOS over TCP/IP wyłączony" "SUCCESS"
        }
        catch {
            Write-Log "Nie można wyłączyć NetBIOS over TCP/IP: $_" "ERROR"
        }
    }
    
    # Konfiguracja UAC
    if ($Settings["UAC"]) {
        try {
            if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System")) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -ErrorAction Stop
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -ErrorAction Stop
            Write-Log "UAC skonfigurowany na najwyższy poziom" "SUCCESS"
        }
        catch {
            Write-Log "Nie można skonfigurować UAC: $_" "ERROR"
        }
    }
    
    # Wyłączenie AutoRun/AutoPlay
    if ($Settings["AutoRun"]) {
        try {
            if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -ErrorAction Stop
            Write-Log "AutoRun/AutoPlay wyłączony" "SUCCESS"
        }
        catch {
            Write-Log "Nie można wyłączyć AutoRun/AutoPlay: $_" "ERROR"
        }
    }
    
    # Wyłączenie Windows Update P2P
    if ($Settings["UpdateP2P"]) {
        try {
            if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0 -ErrorAction Stop
            Write-Log "Wyłączono Windows Update P2P" "SUCCESS"
        }
        catch {
            Write-Log "Błąd podczas konfiguracji Windows Update P2P: $_" "ERROR"
        }
    }
}

# Funkcja czyszczenia PATH
function Clean-PathVariable {
    Write-Log "Czyszczenie zmiennej PATH..."
    
    # Pobieranie aktualnego PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    Write-Log "Sprawdzanie System PATH..."
    $systemPaths = $currentPath -split ";" | Where-Object {$_ -ne ""}
    $validSystemPaths = @()
    $invalidSystemPaths = @()
    
    foreach ($path in $systemPaths) {
        if (Test-Path $path) {
            $validSystemPaths += $path
        } else {
            $invalidSystemPaths += $path
            Write-Log "Nieważna ścieżka w System PATH: $path" "WARNING"
        }
    }
    
    Write-Log "Sprawdzanie User PATH..."
    $userPaths = $userPath -split ";" | Where-Object {$_ -ne ""}
    $validUserPaths = @()
    $invalidUserPaths = @()
    
    foreach ($path in $userPaths) {
        if (Test-Path $path) {
            $validUserPaths += $path
        } else {
            $invalidUserPaths += $path
            Write-Log "Nieważna ścieżka w User PATH: $path" "WARNING"
        }
    }
    
    # Usuwanie duplikatów
    $uniqueSystemPaths = $validSystemPaths | Select-Object -Unique
    $uniqueUserPaths = $validUserPaths | Select-Object -Unique
    
    $removedSystem = $validSystemPaths.Count - $uniqueSystemPaths.Count
    $removedUser = $validUserPaths.Count - $uniqueUserPaths.Count
    
    Write-Log "System PATH: Nieprawidłowe ścieżki: $($invalidSystemPaths.Count), Duplikaty usunięte: $removedSystem" "INFO"
    Write-Log "User PATH: Nieprawidłowe ścieżki: $($invalidUserPaths.Count), Duplikaty usunięte: $removedUser" "INFO"
    
    # Czyszczenie PATH
    [Environment]::SetEnvironmentVariable("PATH", ($uniqueSystemPaths -join ";"), "Machine")
    [Environment]::SetEnvironmentVariable("PATH", ($uniqueUserPaths -join ";"), "User")
    Write-Log "PATH został wyczyszczony!" "SUCCESS"
}

# Funkcja czyszczenia duplikatów firewall
function Clean-FirewallDuplicates {
    Write-Log "Czyszczenie duplikatów reguł firewall..."
    
    $cleaned = 0
    
    # Znajdź reguły z identycznymi nazwami
    $rules = Get-NetFirewallRule
    $ruleNames = $rules | Group-Object DisplayName | Where-Object {$_.Count -gt 1}
    
    foreach ($nameGroup in $ruleNames) {
        $duplicates = $nameGroup.Group
        Write-Log "Duplikat: $($nameGroup.Name) - $($duplicates.Count) kopii" "WARNING"
        
        # Zostaw pierwszą, usuń resztę
        for ($i = 1; $i -lt $duplicates.Count; $i++) {
            Remove-NetFirewallRule -Name $duplicates[$i].Name -ErrorAction SilentlyContinue
            $cleaned++
        }
    }
    
    Write-Log "Usunięto $cleaned duplikatów" "SUCCESS"
}

# Funkcja tworzenia profilu PowerShell
function Create-PowerShellProfile {
    Write-Log "Tworzenie profilu PowerShell z aliasami..."
    
    $profilePath = $PROFILE
    $profileDir = Split-Path $profilePath -Parent
    
    # Tworzenie katalogu profilu jeśli nie istnieje
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force
        Write-Log "Utworzono katalog profilu: $profileDir" "INFO"
    }
    
    # Zawartość profilu
    $profileContent = @'
# ============================================================================
# PROFIL POWERSHELL - POLSKIE ALIASY I FUNKCJE
# Autor: Windows Optimization Tool
# Data utworzenia: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
# ============================================================================

# Ustawienia podstawowe
 $Host.UI.RawUI.WindowTitle = "PowerShell - $env:USERNAME@$env:COMPUTERNAME"

# ============================================================================
# ALIASY LINUXOPODOBNE Z POLSKIMI OPISAMI
# ============================================================================

# === NAWIGACJA I LISTOWANIE ===
Set-Alias -Name lista -Value Get-ChildItem -Description "Wyświetl zawartość katalogu (jak ls)"
Set-Alias -Name ll -Value Get-ChildItem -Description "Szczegółowa lista plików"
Set-Alias -Name katalog -Value Set-Location -Description "Zmień katalog (jak cd)"
Set-Alias -Name gdzie -Value Get-Location -Description "Pokaż aktualny katalog (jak pwd)"

# === OPERACJE NA PLIKACH ===
Set-Alias -Name kopiuj -Value Copy-Item -Description "Kopiuj pliki/katalogi (jak cp)"
Set-Alias -Name przenies -Value Move-Item -Description "Przenieś pliki/katalogi (jak mv)"
Set-Alias -Name usun -Value Remove-Item -Description "Usuń pliki/katalogi (jak rm)"
Set-Alias -Name pokaz -Value Get-Content -Description "Wyświetl zawartość pliku (jak cat)"

# === PROCESY I SYSTEM ===
Set-Alias -Name procesy -Value Get-Process -Description "Pokaż wszystkie procesy (jak ps)"
Set-Alias -Name zabij -Value Stop-Process -Description "Zakończ proces (jak kill)"
Set-Alias -Name dyski -Value Get-Volume -Description "Pokaż informacje o dyskach (jak df)"

# ============================================================================
# ZAAWANSOWANE FUNKCJE Z POLSKIMI NAZWAMI
# ============================================================================

function szybki-skan {
    Write-Host "=== SZYBKI SKAN SYSTEMU ===" -ForegroundColor Cyan
    Write-Host "`nTOP 10 procesów wg CPU:" -ForegroundColor Yellow
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | Format-Table ProcessName, CPU, WorkingSet -AutoSize
    
    Write-Host "`nOtwarte porty nasłuchujące:" -ForegroundColor Yellow
    Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess | Sort-Object LocalPort | Format-Table -AutoSize
}

function info-system {
    Write-Host "=== INFORMACJE O SYSTEMIE ===" -ForegroundColor Cyan
    $os = Get-CimInstance Win32_OperatingSystem
    $comp = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor
    
    Write-Host "`nSystem:" -ForegroundColor Yellow
    Write-Host "  Nazwa: $($os.Caption)"
    Write-Host "  Wersja: $($os.Version)"
    Write-Host "  Komputer: $($comp.Name)"
    
    Write-Host "`nSprzęt:" -ForegroundColor Yellow
    Write-Host "  Procesor: $($cpu.Name)"
    Write-Host "  RAM: $([math]::Round(($comp.TotalPhysicalMemory/1GB), 2)) GB"
}

function czysc-temp {
    Write-Host "Czyszczenie plików tymczasowych..." -ForegroundColor Yellow
    $tempFolders = @($env:TEMP, "$env:WINDIR\Temp", "$env:LOCALAPPDATA\Temp")
    
    foreach ($folder in $tempFolders) {
        if (Test-Path $folder) {
            $files = Get-ChildItem $folder -Recurse -File -ErrorAction SilentlyContinue
            $folderSize = ($files | Measure-Object -Property Length -Sum).Sum
            $fileCount = $files.Count
            
            Write-Host "Katalog: $folder" -ForegroundColor Cyan
            Write-Host "  Pliki: $fileCount, Rozmiar: $([math]::Round($folderSize/1MB, 2)) MB" -ForegroundColor White
            
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Wyczyszczono" -ForegroundColor Green
        }
    }
}

function pomoc-aliasy {
    Write-Host "=== DOSTĘPNE POLSKIE ALIASY ===" -ForegroundColor Cyan
    Write-Host "`nAliasy nawigacji:" -ForegroundColor Yellow
    Write-Host "  lista, ll      - listowanie plików i katalogów"
    Write-Host "  katalog, ..    - zmiana katalogu"
    Write-Host "  gdzie          - aktualny katalog"
    Write-Host "`nAliasy plików:" -ForegroundColor Yellow
    Write-Host "  kopiuj         - kopiowanie plików"
    Write-Host "  przenies       - przenoszenie plików"
    Write-Host "  usun           - usuwanie plików"
    Write-Host "  pokaz          - wyświetlanie zawartości"
    Write-Host "`nAliasy systemowe:" -ForegroundColor Yellow
    Write-Host "  procesy        - lista procesów"
    Write-Host "  zabij          - zabijanie procesów"
    Write-Host "  dyski          - informacje o dyskach"
    Write-Host "`nZaawansowane funkcje:" -ForegroundColor Yellow
    Write-Host "  szybki-skan    - skanowanie systemu"
    Write-Host "  info-system    - informacje o systemie"
    Write-Host "  czysc-temp     - czyszczenie plików temp"
}

# Ustawienie aliasu dla pomocy
Set-Alias -Name pomocy -Value pomoc-aliasy

# Powitanie
Write-Host "PowerShell z polskimi aliasami załadowany!" -ForegroundColor Green
Write-Host "Wpisz 'pomoc-aliasy' aby zobaczyć dostępne komendy" -ForegroundColor Yellow
'@

    # Zapisanie profilu
    $profileContent | Out-File -FilePath $profilePath -Encoding UTF8 -Force
    Write-Log "Profil PowerShell utworzony: $profilePath" "SUCCESS"
}

# Funkcja czyszczenia plików tymczasowych
function Clean-TemporaryFiles {
    Write-Log "Czyszczenie plików tymczasowych..."
    
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
            
            Write-Log "Katalog: $folder - Pliki: $fileCount, Rozmiar: $([math]::Round($folderSize/1MB, 2)) MB" "INFO"
            
            # Usuwanie plików
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Log "Wyczyszczono katalog: $folder" "SUCCESS"
            
            $totalSize += $folderSize
            $totalFiles += $fileCount
        }
    }
    
    Write-Log "Podsumowanie: Usunięto $totalFiles plików, Zwolniono $([math]::Round($totalSize/1MB, 2)) MB" "SUCCESS"
}

# Funkcja tworzenia logu bezpieczeństwa
function Create-SecurityLog {
    Write-Log "Tworzenie logu bezpieczeństwa..."
    
    $logPath = "$env:USERPROFILE\Desktop\Security_Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
    
    # Zbieranie informacji o systemie
    $firewallRules = (Get-NetFirewallRule).Count
    $blockedRules = (Get-NetFirewallRule | Where-Object Action -eq "Block").Count
    
    $logContent = @"
=== Windows Security & Optimization Log ===
Data wykonania: $(Get-Date)
Użytkownik: $env:USERNAME
Komputer: $env:COMPUTERNAME
System: $((Get-CimInstance Win32_OperatingSystem).Caption)

=== STATUS SYSTEMU ===
Firewall rules: $firewallRules
Blocked rules: $blockedRules
UAC: $((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System").EnableLUA)
Telemetry: $((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -ErrorAction SilentlyContinue).AllowTelemetry)

=== WYKONANE OPERACJE ===
 $(Get-Content -Path "$env:USERPROFILE\Desktop\WindowsOptimizationLog_$(Get-Date -Format 'yyyyMMdd').txt" | Select-Object -Last 20 | Out-String)

"@

    $logContent | Out-File -FilePath $logPath -Encoding UTF8
    Write-Log "Rozszerzony log zapisany do: $logPath" "SUCCESS"
}

# Funkcja odświeżania statusu systemu
function Refresh-SystemStatus {
    Write-Log "Odświeżanie statusu systemu..."
    
    $statusText = @"
=== STATUS SYSTEMU ===
Data: $(Get-Date)

SYSTEM:
 $((Get-CimInstance Win32_OperatingSystem).Caption)
Wersja: $((Get-CimInstance Win32_OperatingSystem).Version)

PROCESOR:
 $((Get-CimInstance Win32_Processor).Name)

PAMIĘĆ:
RAM: $([math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB), 2)) GB

FIREWALL:
 $((Get-NetFirewallProfile | Format-Table Name, Enabled | Out-String))

USŁUGI:
 $((Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object -First 10 | Format-Table Name, Status | Out-String))

PORTY:
 $((Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, State | Sort-Object LocalPort | Format-Table | Out-String))
"@

    if ($statusTextBox.InvokeRequired) {
        $statusTextBox.Invoke([System.Action[string]]{
            param($text)
            $statusTextBox.Text = $text
        }, $statusText)
    } else {
        $statusTextBox.Text = $statusText
    }
    
    Write-Log "Status systemu odświeżony" "SUCCESS"
}

# ==============================================================================
# OBSŁUGA ZDARZEŃ
# ==============================================================================

# Zaznacz wszystko
 $selectAllButton.Add_Click({
    foreach ($control in $mainForm.Controls) {
        if ($control -is [System.Windows.Forms.TabControl]) {
            foreach ($tab in $control.TabPages) {
                foreach ($child in $tab.Controls) {
                    if ($child -is [System.Windows.Forms.Panel]) {
                        foreach ($grandchild in $child.Controls) {
                            if ($grandchild -is [System.Windows.Forms.CheckBox]) {
                                $grandchild.Checked = $true
                            }
                        }
                    }
                }
            }
        }
    }
})

# Odznacz wszystko
 $clearAllButton.Add_Click({
    foreach ($control in $mainForm.Controls) {
        if ($control -is [System.Windows.Forms.TabControl]) {
            foreach ($tab in $control.TabPages) {
                foreach ($child in $tab.Controls) {
                    if ($child -is [System.Windows.Forms.Panel]) {
                        foreach ($grandchild in $child.Controls) {
                            if ($grandchild -is [System.Windows.Forms.CheckBox]) {
                                $grandchild.Checked = $false
                            }
                        }
                    }
                }
            }
        }
    }
})

# Uruchom wybrane operacje
 $runButton.Add_Click({
    Write-Log "Rozpoczynanie wybranych operacji..."
    
    # Zbierz wybrane opcje
    $selectedApps = @()
    foreach ($app in $checkboxes.Keys) {
        if ($checkboxes[$app].Checked) {
            $selectedApps += $app
        }
    }
    
    $selectedServices = @()
    foreach ($service in $serviceCheckboxes.Keys) {
        if ($serviceCheckboxes[$service].Checked) {
            $selectedServices += $service
        }
    }
    
    $selectedPorts = @()
    foreach ($port in $portCheckboxes.Keys) {
        if ($portCheckboxes[$port].Checked) {
            $selectedPorts += $port
        }
    }
    
    $selectedSecuritySettings = @{}
    foreach ($setting in $securityCheckboxes.Keys) {
        $selectedSecuritySettings[$setting] = $securityCheckboxes[$setting].Checked
    }
    
    $selectedSystemTools = @()
    foreach ($tool in $systemToolCheckboxes.Keys) {
        if ($systemToolCheckboxes[$tool].Checked) {
            $selectedSystemTools += $tool
        }
    }
    
    # Wykonaj operacje
    if ($selectedApps.Count -gt 0) {
        Remove-BloatwareApps -AppsToRemove $selectedApps
    }
    
    if ($selectedServices.Count -gt 0) {
        Disable-Services -ServicesToDisable $selectedServices
    }
    
    if ($selectedPorts.Count -gt 0) {
        Block-DangerousPorts -PortsToBlock $selectedPorts
    }
    
    if ($selectedSecuritySettings.Values -contains $true) {
        Configure-SecuritySettings -Settings $selectedSecuritySettings
    }
    
    foreach ($tool in $selectedSystemTools) {
        switch ($tool) {
            "RestorePoint" { Create-RestorePoint }
            "CleanPATH" { Clean-PathVariable }
            "CleanFirewall" { Clean-FirewallDuplicates }
            "PowerShellProfile" { Create-PowerShellProfile }
            "CleanTemp" { Clean-TemporaryFiles }
            "SecurityLog" { Create-SecurityLog }
        }
    }
    
    Write-Log "Wszystkie wybrane operacje zakończone!" "SUCCESS"
    [System.Windows.MessageBox]::Show("Wszystkie wybrane operacje zostały zakończone!", "Sukces", "OK", "Information")
})

# Odśwież status
 $refreshStatusButton.Add_Click({
    Refresh-SystemStatus
})

# Wyczyść logi
 $clearLogsButton.Add_Click({
    $logTextBox.Clear()
    Write-Log "Logi zostały wyczyszczone" "INFO"
})

# Zapisz logi
 $saveLogsButton.Add_Click({
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "Pliki tekstowe (*.txt)|*.txt|Wszystkie pliki (*.*)|*.*"
    $saveFileDialog.Title = "Zapisz logi"
    $saveFileDialog.FileName = "WindowsOptimizationLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    if ($saveFileDialog.ShowDialog() -eq "OK") {
        $logTextBox.Text | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
        [System.Windows.MessageBox]::Show("Logi zostały zapisane!", "Sukces", "OK", "Information")
    }
})

# ==============================================================================
# INICJALIZACJA
# ==============================================================================

# Inicjalizacja logów
Write-Log "Windows Optimization & Security Tool v2.0" "INFO"
Write-Log "Uruchomiono jako Administrator" "INFO"

# Odśwież status systemu
Refresh-SystemStatus

# Pokaż formularz
[void]$mainForm.ShowDialog()

# Zakończenie
Write-Log "Aplikacja zamknięta" "INFO"
