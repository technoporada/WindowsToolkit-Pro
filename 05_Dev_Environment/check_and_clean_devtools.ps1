# check_and_clean_devtools.ps1

# =======================
# Sprawdzenie dev-tools
# =======================
Write-Host "=== Sprawdzanie zainstalowanych programów ===" -ForegroundColor Cyan

$programy = @()

# Wykrywanie Pythona w systemie
$pythonDirs = Get-ChildItem 'C:\Python*' -Directory -ErrorAction SilentlyContinue

foreach ($dir in $pythonDirs) {
    $pythonExe = Join-Path $dir.FullName 'python.exe'
    if (Test-Path $pythonExe) {
        $version = (& $pythonExe --version 2>&1).Trim()
        $inPath = ($env:Path -split ';') -contains $dir.FullName
        $programy += [PSCustomObject]@{
            Program = "Python"
            Wersja  = $version
            Sciezka = $dir.FullName
            WPATH   = if ($inPath) { "TAK" } else { "NIE" }
        }
    }
}

# Inne dev-tools
$tools = @(
    @{Name="Node"; Cmd="node"},
    @{Name="Git"; Cmd="git"},
    @{Name="FFmpeg"; Cmd="ffmpeg"},
    @{Name="Choco"; Cmd="choco"}
)

foreach ($tool in $tools) {
    $cmdPath = (Get-Command $tool.Cmd -ErrorAction SilentlyContinue).Source
    if ($cmdPath) {
        $programy += [PSCustomObject]@{
            Program = $tool.Name
            Wersja  = (& $tool.Cmd --version 2>$null | Select-Object -First 1)
            Sciezka = Split-Path $cmdPath
            WPATH   = if (($env:Path -split ';') -contains (Split-Path $cmdPath)) { "TAK" } else { "NIE" }
        }
    }
}

# Wyświetlenie raportu
Write-Host "`n=== Podsumowanie zainstalowanych programów ===" -ForegroundColor Green
$programy | Sort-Object Program | Format-Table -AutoSize

# =======================
# Porządkowanie PATH
# =======================
Write-Host "`n=== Porządkowanie PATH ===" -ForegroundColor Cyan

# Pobranie aktualnego PATH i filtrowanie
$pathList = ($env:Path -split ';') | Where-Object { $_ -ne "" -and (Test-Path $_) } | ForEach-Object { $_.TrimEnd('\') }

# Usunięcie duplikatów
$uniquePathList = $pathList | Select-Object -Unique

# Dodanie brakujących ścieżek dev-tools
$devPaths = $programy | Where-Object { $_.WPATH -eq "NIE" -and $_.Sciezka } | Select-Object -ExpandProperty Sciezka
foreach ($p in $devPaths) {
    if (-not ($uniquePathList -contains $p)) {
        $uniquePathList += $p
        Write-Host "Dodano do PATH: $p" -ForegroundColor Green
    }
}

# Zapis PATH w bieżącej sesji i dla użytkownika
$env:Path = ($uniquePathList -join ';')
[System.Environment]::SetEnvironmentVariable("Path", ($uniquePathList -join ';'), "User")

Write-Host "PATH uporządkowany i zaktualizowany!" -ForegroundColor Green

# Wyświetlenie końcowego PATH
Write-Host "`n=== Aktualny PATH ===" -ForegroundColor Yellow
$uniquePathList | ForEach-Object { Write-Host $_ }
