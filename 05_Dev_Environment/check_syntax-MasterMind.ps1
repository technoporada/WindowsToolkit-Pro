# ===============================
# Deep Scan Syntax Checker - Mastermind Edition
# ===============================

$logFolder = "$PSScriptRoot\syntax_logs"
if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder }

# Foldery, które ignorujemy (oszczędzamy czas i RAM)
$excludeFolders = @(".venv", "node_modules", ".git", "__pycache__")

Write-Output "🚀 Rozpoczynam głębokie skanowanie drzewa katalogów..."

# Funkcja filtrująca foldery
$files = Get-ChildItem -Path $PSScriptRoot -Recurse -File | Where-Object {
    $filePath = $_.FullName
    $shouldExclude = $false
    foreach ($dir in $excludeFolders) {
        if ($filePath -like "*\$dir\*") { $shouldExclude = $true; break }
    }
    -not $shouldExclude
}

foreach ($item in $files) {
    $file = $item.FullName
    
    # --- POWERSHELL ---
    if ($item.Extension -eq ".ps1") {
        Write-Output "🔍 Skasuję PS: $($item.Name)"
        try {
            powershell -NoProfile -Command "Get-Content '$file' | Out-String" -ErrorAction Stop
            Add-Content -Path "$logFolder\ps_syntax_ok.log" -Value $file
        } catch {
            Add-Content -Path "$logFolder\ps_syntax_errors.log" -Value "$file : $_"
        }
    }

    # --- PYTHON ---
    if ($item.Extension -eq ".py") {
        Write-Output "🐍 Skasuję PY: $($item.Name)"
        try {
            python -m py_compile $file
            Add-Content -Path "$logFolder\py_syntax_ok.log" -Value $file
        } catch {
            Add-Content -Path "$logFolder\py_syntax_errors.log" -Value "$file : $_"
        }
    }

    # --- JAVASCRIPT (Bonus dla Twojej platformy AI) ---
    if ($item.Extension -eq ".js") {
        Write-Output "📜 Skasuję JS: $($item.Name)"
        try {
            node --check $file
            Add-Content -Path "$logFolder\js_syntax_ok.log" -Value $file
        } catch {
            Add-Content -Path "$logFolder\js_syntax_errors.log" -Value "$file : $_"
        }
    }
}

Write-Output "✅ Skanowanie zakończone. Wyniki w folderze: syntax_logs"
