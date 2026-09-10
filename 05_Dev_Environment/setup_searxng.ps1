# setup_searxng.ps1 — pobiera i uruchamia SearXNG w Dockerze na Windows 10

# Ustawienie katalogu konfiguracji (jeśli nie istnieje, zostanie utworzony)
$ConfigDir = "$env:USERPROFILE\searxng_config"
if (-Not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir | Out-Null
}

# Pobranie obrazu SearXNG z Dockera
Write-Host "🔹 Pobieram obraz SearXNG z Dockera..."
docker pull searxng/searxng:latest

# Uruchomienie kontenera
Write-Host "🔹 Uruchamiam SearXNG w kontenerze Docker..."
docker run -d `
    -p 8888:8080 `
    -v "${ConfigDir}:/etc/searxng" `
    --name searxng `
    searxng/searxng:latest

Write-Host "✅ SearXNG działa! Otwórz w przeglądarce: http://localhost:8888"
Write-Host "ℹ️ Konfiguracja znajduje się w: $ConfigDir"
