# setup.ps1 - minimalistyczny skrypt instalacji dev tools
# Autor: Arek x ChatGPT (jebac chatgpt)

Write-Host "=== Windows Developer Environment Setup ===" -ForegroundColor Green

# Sprawdzenie uprawnień administratora
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "BŁĄD: Uruchom PowerShell jako Administrator!" -ForegroundColor Red
    Read-Host "Naciśnij Enter aby zakończyć..."
    exit 1
}

# Ustawienie polityki wykonywania
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Instalacja Chocolatey jeśli brak
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "`nInstalacja Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey zainstalowany!" -ForegroundColor Green
} else {
    Write-Host "Chocolatey jest już zainstalowany." -ForegroundColor Yellow
}

# Odświeżenie PATH (żeby choco działało od razu)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Instalacja pakietów z kontrolą wersji i potwierdzeniem
$packages = @(
    @{name='python'; version='3.11.7'},
    @{name='git'},
    @{name='nodejs-lts'},
    @{name='vscode'},
    @{name='notepadplusplus'},
    @{name='7zip'},
    @{name='ffmpeg'}
)

foreach ($pkg in $packages) {
    $name = $pkg.name
    $ver = $pkg.version
    Write-Host "`nInstaluję $name $($ver -ne $null ? $ver : '')..." -ForegroundColor Cyan
    if ($ver) {
        choco install $name --version=$ver -y
    } else {
        choco install $name -y
    }
    Write-Host "$name zainstalowany!" -ForegroundColor Green
}

# Konfiguracja Git - imię i email (opcjonalne)
Write-Host "`nKonfiguracja Git (opcjonalnie):" -ForegroundColor Yellow
$gitName = Read-Host "Podaj swoje imię i nazwisko (może być pseudonim lub cokolwiek)"
if ($gitName) {
    $gitEmail = Read-Host "Podaj swój email do Git"
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    Write-Host "Git skonfigurowany!" -ForegroundColor Green
} else {
    Write-Host "Konfiguracja Git pominięta." -ForegroundColor Yellow
}

# Dodanie prostych aliasów do PowerShell Profile
$profilePath = $PROFILE
if (!(Test-Path -Path $profilePath)) {
    New-Item -Type File -Path $profilePath -Force | Out-Null
}
$aliases = @"
# Alias i funkcje Arek x ChatGPT - bez polskich znaków!
function ll { Get-ChildItem -Force }
function gs { git status }
function npmi { npm install }
function cls { Clear-Host }
function projcd { Set-Location 'D:\' }
"@

Add-Content -Path $profilePath -Value $aliases
Write-Host "Alias i helpery PowerShell dodane do profilu: $profilePath" -ForegroundColor Green

Write-Host "`n=== Instalacja zakończona! ===" -ForegroundColor Green
Write-Host "Zainstalowane pakiety: Python, Git, Node.js LTS, VSCode, Notepad++, 7-Zip, FFmpeg" -ForegroundColor White
Write-Host "Zrestartuj PowerShell lub komputer, aby zmiany PATH i profilowe zaczęły działać." -ForegroundColor Yellow

