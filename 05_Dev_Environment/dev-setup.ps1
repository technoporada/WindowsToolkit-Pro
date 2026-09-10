<#
.SYNOPSIS
    Setup środowiska developera z konfigurowalnymi ścieżkami
.PARAMETER DevRoot
    Główny katalog dev. Domyślnie: $HOME\Dev
#>
param(
    [string]$DevRoot = "$HOME\Dev"
)

Write-Host "=== Dev Environment Setup ===" -ForegroundColor Cyan
Write-Host "Katalog główny: $DevRoot" -ForegroundColor Yellow

$folders = @(
    "$DevRoot",
    "$DevRoot\Projects",
    "$DevRoot\Tools",
    "$DevRoot\Temp",
    "$DevRoot\Logs"
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Write-Host "  📁 Created: $folder" -ForegroundColor Gray
    }
}

Write-Host "`n✅ Struktura katalogów gotowa w $DevRoot" -ForegroundColor Green
