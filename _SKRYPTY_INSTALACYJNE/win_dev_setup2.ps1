# Windows Developer Environment Setup Script
# Uruchom jako Administrator w PowerShell

Write-Host "=== Windows Developer Environment Setup ===" -ForegroundColor Green
Write-Host "Ten skrypt zainstaluje wszystkie niezbedne narzedzia deweloperskie" -ForegroundColor Yellow

# Sprawdz czy skrypt jest uruchomiony jako Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "BLAD: Uruchom PowerShell jako Administrator!" -ForegroundColor Red
    Write-Host "Nacisnij Enter aby zakonczyc..."
    Read-Host
    exit 1
}

# Ustaw politykę wykonywania skryptów
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Instalacja Chocolatey (menedżer pakietów dla Windows)
Write-Host "`n[1/10] Instalowanie Chocolatey..." -ForegroundColor Cyan
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey zainstalowany!" -ForegroundColor Green
} else {
    Write-Host "Chocolatey już zainstalowany!" -ForegroundColor Yellow
}

# Odswiez zmienne srodowiskowe
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Instalacja Python
Write-Host "`n[2/10] Instalowanie Python..." -ForegroundColor Cyan
choco install python -y
Write-Host "Python zainstalowany!" -ForegroundColor Green

# Instalacja Node.js
Write-Host "`n[3/10] Instalowanie Node.js..." -ForegroundColor Cyan
choco install nodejs -y
Write-Host "Node.js zainstalowany!" -ForegroundColor Green

# Instalacja Git
Write-Host "`n[4/10] Instalowanie Git..." -ForegroundColor Cyan
choco install git -y
Write-Host "Git zainstalowany!" -ForegroundColor Green

# Instalacja Visual Studio Code
Write-Host "`n[5/10] Instalowanie Visual Studio Code..." -ForegroundColor Cyan
choco install vscode -y
Write-Host "Visual Studio Code zainstalowany!" -ForegroundColor Green

# Instalacja Docker Desktop
Write-Host "`n[6/10] Instalowanie Docker Desktop..." -ForegroundColor Cyan
choco install docker-desktop -y
Write-Host "Docker Desktop zainstalowany!" -ForegroundColor Green

# Instalacja Windows Terminal
Write-Host "`n[7/10] Instalowanie Windows Terminal..." -ForegroundColor Cyan
choco install microsoft-windows-terminal -y
Write-Host "Windows Terminal zainstalowany!" -ForegroundColor Green

# Instalacja 7-Zip
Write-Host "`n[8/10] Instalowanie 7-Zip..." -ForegroundColor Cyan
choco install 7zip -y
Write-Host "7-Zip zainstalowany!" -ForegroundColor Green

# Instalacja Postman
Write-Host "`n[9/10] Instalowanie Postman..." -ForegroundColor Cyan
choco install postman -y
Write-Host "Postman zainstalowany!" -ForegroundColor Green

# Odswiez zmienne srodowiskowe ponownie
Write-Host "`n[10/10] Odswiezanie zmiennych srodowiskowych..." -ForegroundColor Cyan
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Instalacja dodatkowych pakietow Python
Write-Host "`nInstalowanie podstawowych pakietow Python..." -ForegroundColor Cyan
try {
    python -m pip install --upgrade pip
    python -m pip install requests numpy pandas matplotlib seaborn jupyter notebook flask django fastapi
    Write-Host "Pakiety Python zainstalowane!" -ForegroundColor Green
} catch {
    Write-Host "Blad podczas instalacji pakietow Python. Sprobuj pozniej recznie." -ForegroundColor Red
}

# Instalacja globalnych pakietow npm
Write-Host "`nInstalowanie globalnych pakietow npm..." -ForegroundColor Cyan
try {
    npm install -g typescript nodemon create-react-app @angular/cli @vue/cli
    Write-Host "Globalne pakiety npm zainstalowane!" -ForegroundColor Green
} catch {
    Write-Host "Blad podczas instalacji pakietow npm. Sprobuj pozniej recznie." -ForegroundColor Red
}

# Konfiguracja Git (opcjonalnie)
Write-Host "`nKonfiguracja Git (opcjonalnie):" -ForegroundColor Yellow
$gitName = Read-Host "Podaj swoje imie i nazwisko dla Git (lub nacisnij Enter aby pominac)"
if ($gitName) {
    $gitEmail = Read-Host "Podaj swoj email dla Git"
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    Write-Host "Git skonfigurowany!" -ForegroundColor Green
}

# Podsumowanie
Write-Host "`n=== INSTALACJA ZAKONCZONA ===" -ForegroundColor Green
Write-Host "Zainstalowane narzedzia:" -ForegroundColor White
Write-Host "√ Python + pip + podstawowe pakiety" -ForegroundColor Green
Write-Host "√ Node.js + npm + TypeScript, React CLI, Angular CLI, Vue CLI" -ForegroundColor Green
Write-Host "√ Git" -ForegroundColor Green
Write-Host "√ Visual Studio Code" -ForegroundColor Green
Write-Host "√ Docker Desktop" -ForegroundColor Green
Write-Host "√ Windows Terminal" -ForegroundColor Green
Write-Host "√ 7-Zip" -ForegroundColor Green
Write-Host "√ Postman" -ForegroundColor Green
Write-Host "√ Chocolatey (menedzer pakietow)" -ForegroundColor Green

Write-Host "`nUWAGI:" -ForegroundColor Yellow
Write-Host "1. Zrestartuj komputer aby wszystkie zmiany zostaly zastosowane" -ForegroundColor White
Write-Host "2. Docker Desktop wymaga restartu i wlaczenia WSL2" -ForegroundColor White
Write-Host "3. Sprawdz czy wszystko dziala otwierajac nowy terminal i wpisujac:" -ForegroundColor White
Write-Host "   python --version" -ForegroundColor Gray
Write-Host "   node --version" -ForegroundColor Gray
Write-Host "   git --version" -ForegroundColor Gray

Write-Host "`nNacisnij Enter aby zakonczyc..." -ForegroundColor Green
Read-Host
