<#
.SYNOPSIS
    Czyści cache npm i inne zbędne pliki Node.js
#>

$tempDirs = @(
    "$env:TEMP\npm-*",
    "$env:LOCALAPPDATA\npm-cache",
    "$env:APPDATA\npm",
    "$env:USERPROFILE\.npm\_logs"
)

Write-Host "Czyszczenie cache Node.js..." -ForegroundColor Yellow

foreach ($dir in $tempDirs) {
    $items = Get-Item $dir -ErrorAction SilentlyContinue
    if ($items) {
        foreach ($item in $items) {
            Write-Host "  Usuwam: $($item.FullName)" -ForegroundColor Gray
            Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Wyczyść tymczasowe pliki npm
Get-ChildItem "$env:TEMP\npm-*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

Write-Host "✅ Cache npm wyczyszczony" -ForegroundColor Green
