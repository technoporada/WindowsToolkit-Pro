# =========================
# ENV-SETUP – POLSKA WERSJA
# =========================

function Safe-Write {
    param($msg)
    Write-Host $msg -ForegroundColor Cyan
}

# Backup PATH
$backupPath = "$env:TEMP\path-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
Safe-Write "Tworzenie kopii PATH: $backupPath"
$env:PATH.Split(';') | Out-File $backupPath

# Usuń duplikaty/missing
$machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
$pathArray = $machinePath.Split(';') | Where-Object { $_ -ne "" } | Sort-Object -Unique
Safe-Write "Podgląd PATH po usunięciu duplikatów i brakujących wpisów:"
$pathArray | ForEach-Object { Write-Host " - $_" }

$applyPath = Read-Host "Chcesz zapisać nowy PATH do systemu? (t/n) [domyślnie n]"
if ($applyPath -eq "t") {
    [System.Environment]::SetEnvironmentVariable("PATH", ($pathArray -join ";"), "Machine")
    Safe-Write "Nowy PATH zapisany."
} else {
    Safe-Write "Pominięto zapis PATH."
}

# Winget instalacja narzędzi
$winget = Get-Command winget -ErrorAction SilentlyContinue
if ($winget) {
    $tools = @("PowerShell","Windows Terminal","Notepad++","Git","Visual Studio Code")
    Safe-Write "Dostępne pakiety do instalacji:"
    $i = 0
    $tools | ForEach-Object { Write-Host "[$i] $_"; $i++ }

    $install = Read-Host "Wpisz indeksy pakietów do instalacji (przecinki) lub Enter aby pominąć"
    if ($install) {
        $indexes = $install -split ',' | ForEach-Object { $_.Trim() }
        foreach ($idx in $indexes) {
            $pkg = $tools[$idx]
            Safe-Write "Instalacja $pkg..."
            winget install --id $pkg --silent
        }
    }
} else {
    Safe-Write "Nie znaleziono winget. Pominięto instalację narzędzi."
}

# Alias w profilu PowerShell
$profileFile = "$HOME\Documents\WindowsPowerShell\profile.ps1"
if (!(Test-Path $profileFile)) { New-Item -ItemType File -Path $profileFile -Force }
Add-Content $profileFile "`n# Proste aliasy`nSet-Alias lista Get-ChildItem`nSet-Alias katalog Set-Location"
Safe-Write "Profile PowerShell zaktualizowany: $profileFile"

# Opcjonalne funkcje
$installWSL = Read-Host "Zainstalować funkcje WSL? (t/n) [domyślnie n]"
if ($installWSL -eq "t") {
    Safe-Write "Instalacja WSL..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
}

$firewall = Read-Host "Dodać reguły firewall blokujące typowe porty RPC/SMB/RDP/WinRM? (t/n) [domyślnie n]"
if ($firewall -eq "t") {
    $ports = @(135, 139, 445, 5040, 2179)
    foreach ($p in $ports) {
        New-NetFirewallRule -DisplayName "Blokada port $p" -Direction Inbound -LocalPort $p -Protocol TCP -Action Block -ErrorAction SilentlyContinue
        Safe-Write "Port $p zablokowany."
    }
}

$telemetry = Read-Host "Zatrzymać wybrane usługi telemetryczne? (t/n) [domyślnie n]"
if ($telemetry -eq "t") {
    $services = @("DiagTrack","dmwappushservice","WpnService")
    foreach ($s in $services) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        Set-Service $s -StartupType Disabled
        Safe-Write "Usługa $s zatrzymana i wyłączona."
    }
}

Safe-Write "`n=== SKRYPT ZAKOŃCZONY ==="
