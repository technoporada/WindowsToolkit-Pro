# =========================================
# ArekFlix OS – Setup Script
# PowerShell
# =========================================

# 1. Sprawdzenie i instalacja Python 3.12+ (winget)
Write-Host "Sprawdzam Pythona..."
python --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Instaluję Pythona 3.12..."
    winget install Python.Python.3.12 -e
}

# 2. Tworzenie folderów projektu
$folders = @(
    "ArekFlixOS",
    "ArekFlixOS\modules",
    "ArekFlixOS\templates",
    "ArekFlixOS\static",
    "ArekFlixOS\static\icons",
    "ArekFlixOS\static\sounds",
    "ArekFlixOS\static\themes"
)
foreach ($f in $folders) {
    if (-Not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f
    }
}

# 3. Instalacja bibliotek Python
Write-Host "Instalacja bibliotek Python..."
python -m pip install --upgrade pip
python -m pip install fastapi uvicorn gradio requests beautifulsoup4 sqlite3 pyttsx3 SpeechRecognition pyaudio

# 4. Tworzenie pliku konfiguracyjnego
$configPath = "ArekFlixOS\config.py"
if (-Not (Test-Path $configPath)) {
    @"
# ArekFlixOS – Konfiguracja
RADIO_STREAMS = []
TV_STREAMS = []
USER_PREFERENCES_DB = 'user_preferences.sqlite'
CHILL_PLAYLIST = []
"@ | Out-File $configPath -Encoding UTF8
}

Write-Host "Setup zakończony! Gotowy do uruchomienia ArekFlixOS."
