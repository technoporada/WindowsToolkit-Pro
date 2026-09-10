Write-Host "=== Sprawdzanie zainstalowanych programów i dev-tools ===" -ForegroundColor Cyan

# Pobranie listy z winget (pomijamy nagłówek)
$wingetList = winget list --source winget | Select-Object -Skip 1
$programy = @()

foreach ($line in $wingetList) {
    $parts = $line -split '\s{2,}'
    if ($parts.Count -ge 2) {
        $nazwa = $parts[0].Trim()
        $wersja = $parts[1].Trim()
        $sciezka = ""

        # Próba pobrania ścieżki instalacji z rejestru
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        $keys = Get-ChildItem $regPath
        foreach ($key in $keys) {
            $displayName = (Get-ItemProperty $key.PSPath -Name DisplayName -ErrorAction SilentlyContinue).DisplayName
            if ($displayName -and $displayName -like "*$nazwa*") {
                $sciezka = (Get-ItemProperty $key.PSPath -Name InstallLocation -ErrorAction SilentlyContinue).InstallLocation
                if (!$sciezka) { $sciezka = (Get-ItemProperty $key.PSPath -Name UninstallString -ErrorAction SilentlyContinue).UninstallString }
                break
            }
        }

        $inPath = $false
        if ($sciezka) {
            $pathList = $env:Path -split ';'
            foreach ($p in $pathList) {
                if ($p.TrimEnd('\').ToLower() -ieq $sciezka.TrimEnd('\').ToLower()) { $inPath = $true; break }
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

# Dev-tools do sprawdzenia
$devTools = @(
    @{Name="Python"; Cmd="python"},
    @{Name="Node"; Cmd="node"},
    @{Name="Git"; Cmd="git"},
    @{Name="FFmpeg"; Cmd="ffmpeg"},
    @{Name="Choco"; Cmd="choco"}
)

foreach ($tool in $devTools) {
    $cmdPath = (Get-Command $tool.Cmd -ErrorAction SilentlyContinue).Source
    if ($cmdPath) {
        $inPath = $false
        $pathList = $env:Path -split ';'
        foreach ($p in $pathList) {
            if ($cmdPath.ToLower() -like ($p.TrimEnd('\').ToLower() + "*")) { $inPath = $true; break }
        }

        $programy += [PSCustomObject]@{
            Program = $tool.Name
            Wersja  = (& $tool.Cmd --version 2>$null | Select-Object -First 1)
            Sciezka = $cmdPath
            WPATH   = if ($inPath) { "TAK" } else { "NIE" }
        }
    }
}

# Wyświetlenie tabeli
Write-Host "`n=== Podsumowanie ===" -ForegroundColor Green
$programy | Sort-Object Program | Format-Table -AutoSize

# --- Porządkowanie PATH ---
Write-Host "`n=== Porządkowanie PATH ===" -ForegroundColor Cyan

# Normalizacja PATH
$pathList = ($env:Path -split ';') | Where-Object { $_ -ne "" } | ForEach-Object { $_.TrimEnd('\').ToLower() }
$uniquePathList = $pathList | Select-Object -Unique

# Dodanie brakujących ścieżek dev-tools
$devToolsPaths = $programy | Where-Object { $_.WPATH -eq "NIE" -and $_.Sciezka } | Select-Object -ExpandProperty Sciezka

foreach ($p in $devToolsPaths) {
    $normalizedPath = $p.TrimEnd('\').ToLower()
    if ((-not ($uniquePathList -contains $normalizedPath)) -and (Test-Path $p)) {
        $uniquePathList += $normalizedPath
        Write-Host "Dodano do PATH: $p" -ForegroundColor Green
    }
}

# Aktualizacja PATH
$env:Path = ($uniquePathList -join ';')
[System.Environment]::SetEnvironmentVariable("Path", ($uniquePathList -join ';'), "User")
Write-Host "PATH uporządkowany i zaktualizowany!" -ForegroundColor Green

# Wyświetlenie końcowego PATH
Write-Host "`n=== Aktualny PATH ===" -ForegroundColor Yellow
$uniquePathList | ForEach-Object { Write-Host $_ }
