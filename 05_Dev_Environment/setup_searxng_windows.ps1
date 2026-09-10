<#
    One-click SearXNG setup for Windows 10
    Uruchom w PowerShell jako Administrator
#>

# 1. Sprawdź, czy Docker jest zainstalowany
if (-Not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Output "Docker nie jest zainstalowany. Pobieram Docker Desktop..."
    Start-Process "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -Wait
    Write-Output "Zainstaluj Docker Desktop ręcznie, używając domyślnych opcji (nie zaznaczaj Windows Containers)."
    exit
}

# 2. Uruchom Docker Desktop jeśli nie działa
$dockerStatus = docker info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "Uruchamiam Docker Desktop..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Output "Poczekaj chwilę aż Docker w pełni wystartuje, a potem uruchom skrypt ponownie."
    exit
}

# 3. Pobierz najnowszy obraz SearXNG
Write-Output "Pobieram obraz SearXNG..."
docker pull searxng/searxng

# 4. Utwórz folder konfiguracji
$ConfigDir = "$env:USERPROFILE\searxng"
if (-Not (Test-Path $ConfigDir)) { 
    Write-Output "Tworzę folder konfiguracji: $ConfigDir"
    New-Item -ItemType Directory -Path $ConfigDir | Out-Null
}

# 5
