# full_system_path_cleaner.ps1
# Skrypt do skanowania wszystkich programów, porządkowania PATH i dev-tools

Write-Host "=== Skanning wszystkich programów ===" -ForegroundColor Cyan

$programy = @()

# 1. Pobranie programów z winget
try {
    $wingetList = winget list --source winget 2>$null | Select-Object -Skip 1
    foreach ($line in $wingetList) {
        $parts = $line -split '\s{2,}'
        if ($parts.Count -ge 2) {
            $nazwa = $parts[0].Trim()
            $wersja = $parts[1].Trim()
            $sciezka = ""

            # Próba pobrania ścieżki instalacji z rejestru
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
            $keys = Get-ChildItem $regPath -ErrorAction SilentlyContinue
            foreach ($key in $keys) {
                $displayName = (Get-ItemProperty $key.PSPath -Name DisplayName -ErrorAction SilentlyContinue).DisplayName
                if ($displayName -and $displayName -like "*$nazwa*") {
                    $sciezka = (Get-ItemProperty $key.PSPath -Name InstallLocation -ErrorAction SilentlyContinue).InstallLocation
                    if (!$sciezka) {
                        $sciezka = (Get-ItemProperty $key.PSPath -Name UninstallString -ErrorAction SilentlyContinue).UninstallString
                    }
                    break
                }
            }

            # Sprawdzenie czy jest w PATH
            $inPath = $false
            if ($sciezka) {
                $pathList = ($env:Path -split ';') | ForEach-Object { $_.TrimEnd('\') }
                foreach ($p in $pathList) {
                    if ($p -ieq $sciezka.TrimEnd('\')) { $inPath = $true; break }
                }
            }

            $programy += [PSCustomObject]@{
                Program = $nazwa
                Wersja  = $wersja
                Sciezka = $sciezka
                WPATH   = if ($inPath) { "TAK" } else { "NIE" }
            }
        }
    }
} catch {}

# 2. Dev-tools i Python w standardowych lokalizacjach
$devTools = @(
    @{Name="Python"; Pattern="Python*"},
    @{Name="Node"; Cmd="node"},
    @{Name="Git"; Cmd="git"},
    @{Name="FFmpeg"; Cmd="ffmpeg"},
    @{Name="Choco"; Cmd="choco"}
)

# Pythony w C:\Python*
$pythonDirs = Get-ChildItem C:\Python* -Directory -ErrorAction SilentlyContinue
foreach ($py in $pythonDirs) {
    $exePath = Join-Path $py.FullName "python.exe"
    if (Test-Path $exePath) {
        $ver = (& $exePath --version 2>&1).Trim()
        $inPath = $false
        $pathList = ($env:Path -split ';') | ForEach-Object { $_.TrimEnd('\') }
        foreach ($p in $pathList) {
            if ($p -ieq $py.FullName) { $inPath = $true; break }
        }
        $programy += [PSCustomObject]@{
            Program = "Python"
            Wersja  = $ver
            Sciezka = $py.FullName
            WPATH   = if ($inPath) { "TAK" } else { "NIE" }
        }
    }
}

# Pozostałe dev-tools
foreach ($tool in $devTools | Where-Object { $_.Name -ne "Python" }) {
    $cmdPath = (Get-Command $tool.Cmd -ErrorAction SilentlyContinue).Source
    if ($cmdPath) {
        $ver = (& $tool.Cmd --version 2>$null | Select-Object -First 1).Trim()
        $inPath = $false
        $pathList = ($env:Path -split ';') | ForEach-Object { $_.TrimEnd('\') }
        foreach ($p in $pathList) {
            if ($cmdPath -like "$p*") { $inPath = $true; break }
        }
        $programy += [PSCustomObject]@{
            Program = $tool.Name
            Wersja  = $ver
            Sciezka = $cmdPath
            WPATH   = if ($inPath) { "TAK" } else { "NIE" }
        }
    }
}

# Wyświetlenie tabeli
Write-Host "`n=== Podsumowanie zainstalowanych programów ===" -ForegroundColor Green
$programy | Sort-Object Program, Wersja | Format-Table -AutoSize

# 3. Porządkowanie PATH
Write-Host "`n=== Porządkowanie PATH ===" -ForegroundColor Cyan
$pathList = ($env:Path -split ';') | Where-Object { $_ -ne "" } | ForEach-Object { $_.TrimEnd('\') }
$uniquePathList = $pathList | Select-Object -Unique

# Dodanie brakujących ścieżek automatycznie
$missingPaths = $programy | Where-Object { $_.WPATH -eq "NIE" -and $_.Sciezka } | Select-Object -ExpandProperty Sciezka
foreach ($p in $missingPaths) {
    if (-not ($uniquePathList -contains $p.TrimEnd('\'))) {
        $uniquePathList += $p.TrimEnd('\')
        Write-Host "Dodano do PATH: $p" -ForegroundColor Green
    }
}

# Zapisanie PATH w bieżącej sesji i dla użytkownika
$env:Path = ($uniquePathList -join ';')
[System.Environment]::SetEnvironmentVariable("Path", ($uniquePathList -join ';'), "User")

Write-Host "PATH uporządkowany i zaktualizowany!" -ForegroundColor Green

# Wyświetlenie końcowego PATH
Write-Host "`n=== Aktualny PATH ===" -ForegroundColor Yellow
$uniquePathList | ForEach-Object { Write-Host $_ }
