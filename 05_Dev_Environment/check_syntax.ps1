# ===============================
# Sprawdzenie składni PowerShell i Pythona
# ===============================

$logFolder = "$PSScriptRoot\syntax_logs"
if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder }

# 1. PowerShell
Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 | ForEach-Object {
    $file = $_.FullName
    Write-Output "=== Sprawdzanie PS: $file ==="
    try {
        # Weryfikacja składni
        powershell -NoProfile -Command "powershell -Command {Get-Content '$file' | Out-String}" -ErrorAction Stop
        Add-Content -Path "$logFolder\ps_syntax_ok.log" -Value $file
    } catch {
        Add-Content -Path "$logFolder\ps_syntax_errors.log" -Value "$file : $_"
    }
}

# 2. Python
Get-ChildItem -Path $PSScriptRoot -Filter *.py | ForEach-Object {
    $file = $_.FullName
    try {
        python -m py_compile $file
        Add-Content -Path "$logFolder\py_syntax_ok.log" -Value $file
    } catch {
        Add-Content -Path "$logFolder\py_syntax_errors.log" -Value "$file : $_"
    }
}

Write-Output "Sprawdzenie zakończone. Logi w $logFolder"
