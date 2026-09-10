# Windows Developer Environment Setup Script
# Uruchom jako Administrator w PowerShell

Write-Host "=== Windows Developer Environment Setup ===" -ForegroundColor Green
Write-Host "Ten skrypt zainstaluje narzedzia deweloperskie na Windows" -ForegroundColor Yellow

# Sprawdzenie uprawnien administratora
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "BLAD: Uruchom PowerShell jako Administrator!" -ForegroundColor Red
    Read-Host "Nacisnij Enter aby zakonczyc..."
    exit 1
}

# Ustawienie polityki wykonywania
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Instalacja Chocolatey
Write-Host "`n[1/10] Instalowanie Chocolatey..." -ForegroundColor Cyan
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey zainstalowany!" -ForegroundColor Green
} else {
    Write-Host "Chocolatey juz zainstalowany!" -ForegroundColor Yellow
}

# Odświeżenie zmiennych PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Instalacja Python (specyficzna wersja)
Write-Host "`n[2/10] Instalowanie Python 3.11.7..." -ForegroundColor Cyan
choco install python --version=3.11.7 -y
Write-Host "Python 3.11.7 zainstalowany!" -ForegroundColor Green

# Instalacja Git
Write-Host "`n[3/10] Instalowanie Git..." -ForegroundColor Cyan
choco install git -y
Write-Host "Git zainstalowany!" -ForegroundColor Green

# Instalacja Node.js
Write-Host "`n[4/10] Instalowanie Node.js..." -ForegroundColor Cyan
choco install nodejs -y
Write-Host "Node.js zainstalowany!" -ForegroundColor Green

# [DODATKI] - Narzędzia systemowe, terminalowe i API

# Instalacja Everything
Write-Host "`n[D1] Instalowanie Everything..." -ForegroundColor Cyan
choco install everything -y
Write-Host "Everything zainstalowany!" -ForegroundColor Green

# Instalacja Autoruns
Write-Host "`n[D2] Instalowanie Autoruns..." -ForegroundColor Cyan
choco install autoruns -y
Write-Host "Autoruns zainstalowany!" -ForegroundColor Green

# Instalacja curl (na wszelki wypadek)
Write-Host "`n[D3] Instalowanie curl..." -ForegroundColor Cyan
choco install curl -y
Write-Host "curl zainstalowany!" -ForegroundColor Green

# Instalacja Oh My Posh
Write-Host "`n[D4] Instalowanie Oh My Posh..." -ForegroundColor Cyan
choco install oh-my-posh -y
Write-Host "Oh My Posh zainstalowany!" -ForegroundColor Green

# Dodanie do PowerShell profile (jeśli jeszcze nie ma)
if (!(Select-String -Path $PROFILE -Pattern 'oh-my-posh' -Quiet)) {
    "`noh-my-posh init pwsh --config `"$env:POSH_THEMES_PATH\paradox.omp.json`" | Invoke-Expression" | Out-File -Encoding UTF8 -Append -FilePath $PROFILE
    Write-Host "Dodano konfigurację Oh My Posh do profilu PowerShell!" -ForegroundColor Green
} else {
    Write-Host "Konfiguracja Oh My Posh już obecna w profilu PowerShell." -ForegroundColor Yellow
}

# Instalacja virtualenv
Write-Host "`n[D5] Instalowanie virtualenv (dla Python)..." -ForegroundColor Cyan
python -m pip install virtualenv
Write-Host "virtualenv zainstalowany!" -ForegroundColor Green

# Instalacja httpie (fajny curl)
Write-Host "`n[D6] Instalowanie httpie..." -ForegroundColor Cyan
choco install httpie -y
Write-Host "httpie zainstalowany!" -ForegroundColor Green

# Instalacja git-credential-manager
Write-Host "`n[D7] Instalowanie Git Credential Manager..." -ForegroundColor Cyan
choco install git-credential-manager-core -y
Write-Host "Git Credential Manager zainstalowany!" -ForegroundColor Green

# Instalacja VS Code
Write-Host "`n[5/10] Instalowanie Visual Studio Code..." -ForegroundColor Cyan
choco install vscode -y
Write-Host "VS Code zainstalowany!" -ForegroundColor Green

# Instalacja Notepad++
Write-Host "`n[6/10] Instalowanie Notepad++..." -ForegroundColor Cyan
choco install notepadplusplus -y
Write-Host "Notepad++ zainstalowany!" -ForegroundColor Green
Write-Host "UWAGA: Ustaw domyslne kodowanie na UTF-8 bez BOM w Notepad++." -ForegroundColor Yellow

# Instalacja 7-Zip
Write-Host "`n[7/10] Instalowanie 7-Zip..." -ForegroundColor Cyan
choco install 7zip -y
Write-Host "7-Zip zainstalowany!" -ForegroundColor Green

# Instalacja Aria2 + konfiguracja RPC
Write-Host "`n[9/10] Instalowanie Aria2 + konfiguracja RPC..." -ForegroundColor Cyan
choco install aria2 -y

$aria2Folder = "C:\Tools\aria2"
New-Item -ItemType Directory -Path $aria2Folder -Force | Out-Null

# Plik konfiguracyjny aria2
$aria2ConfPath = Join-Path $aria2Folder "aria2.conf"
@"
enable-rpc=true
rpc-listen-all=true
rpc-allow-origin-all=true
dir=D:/Pobrane
continue=true
max-concurrent-downloads=5
split=16
min-split-size=1M
"@ | Set-Content -Encoding UTF8 -Path $aria2ConfPath

# Tworzenie skrótu do autostartu
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutPath = Join-Path $StartupFolder "Aria2 AutoStart.lnk"
$TargetPath = (Get-Command aria2c).Source
$Arguments = "--conf-path=`"$aria2ConfPath`""

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $TargetPath
$Shortcut.Arguments = $Arguments
$Shortcut.WorkingDirectory = $aria2Folder
$Shortcut.WindowStyle = 7
$Shortcut.Description = "Start Aria2 with RPC"
$Shortcut.Save()

Write-Host "Aria2 zainstalowany i skonfigurowany z RPC!" -ForegroundColor Green
Write-Host "Dodano do autostartu. Pobieranie przez przegladarke gotowe!" -ForegroundColor Green

# Instalacja ffmpeg
Write-Host "`n[8/10] Instalowanie FFmpeg..." -ForegroundColor Cyan
choco install ffmpeg -y
Write-Host "FFmpeg zainstalowany!" -ForegroundColor Green

# Instalacja pakietow Python
Write-Host "`n[9/10] Instalowanie pakietow Python..." -ForegroundColor Cyan
python -m pip install --upgrade pip
python -m pip install flask django fastapi requests numpy pandas matplotlib seaborn jupyter
Write-Host "Pakiety Python zainstalowane!" -ForegroundColor Green

# Instalacja globalnych pakietow npm
Write-Host "`n[10/10] Instalowanie pakietow npm..." -ForegroundColor Cyan
npm install -g typescript nodemon create-react-app @angular/cli @vue/cli
Write-Host "Pakiety npm zainstalowane!" -ForegroundColor Green

# Konfiguracja Git
Write-Host "`nKonfiguracja Git (opcjonalnie):" -ForegroundColor Yellow
$gitName = Read-Host "Podaj swoje imie i nazwisko (moze byc pseudonim)"
if ($gitName) {
    $gitEmail = Read-Host "Podaj swoj email dla Git"
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    Write-Host "Git skonfigurowany!" -ForegroundColor Green
}

# Dodanie podstawowego profilu PowerShell
$profileContent = @"
# PowerShell Profile - aliasy i skróty
function ll { Get-ChildItem -Force }
function gs { git status }
function npmi { npm install }
function clear { Clear-Host }
function projcd { Set-Location 'D:\\' }
"@

if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
$profileContent | Out-File -Encoding UTF8 -Append -FilePath $PROFILE
Write-Host "PowerShell Profile zaktualizowany!" -ForegroundColor Green

# Podsumowanie
Write-Host "`n=== INSTALACJA ZAKONCZONA ===" -ForegroundColor Green
Write-Host "Zainstalowane narzedzia: Python, Node.js, Git, VSCode, Notepad++, FFmpeg, 7-Zip" -ForegroundColor White
Write-Host "Zrestartuj komputer aby zmiany PATH byly w pelni aktywne." -ForegroundColor Yellow
Write-Host "âš Aria2 + RPC + Autostart + Konfiguracja folderu D:\Pobrane" -ForegroundColor Green
Write-Host ""
Write-Host "Aby pobierac przez Chrome z Aria2, zainstaluj rozszerzenie:" -ForegroundColor Yellow
Write-Host "🔗 https://chrome.google.com/webstore/detail/aria2-integration/jdgeagcckblbkgbjafjhfjhjaadefdok" -ForegroundColor Gray
Write-Host "i upewnij sie, ze aria2 uruchomil sie przy starcie systemu." -ForegroundColor Yellow
Read-Host "Nacisnij Enter aby zakonczyc..."
