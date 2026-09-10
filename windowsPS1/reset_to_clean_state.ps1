<#
reset-to-clean-state.ps1
Opis: Skrypt przywracający porządek po eksperymentach z Dev/Music tools.
Cechy:
 - tworzy backup usuwanych plików do katalogu backups w tym samym folderze co skrypt
 - usuwa katalogi C:\Tools\{Aria2,yt-dlp,ffmpeg,Peace,mpv,vlc} jeśli istnieją
 - usuwa katalogi konfiguracyjne użytkownika: .spotdl, .bandcamp-dl, .config\yt-dlp, .config\aria2 itp.
 - próbuje odinstalować pakiety przez Chocolatey i/lub winget (jeśli zainstalowane)
 - czyści wpisy PATH zawierające C:\Tools i duplikaty
 - usuwa autostartowy skrót Aria2 (jeśli występuje)
 - czyści aliasy/funkcje dodane do profilu PowerShell (mp3yt, zgrajspoti, bandcampdl, ytvideo itp.)
 - zapisuje log w katalogu skryptu

Uwaga: skrypt wykonuje operacje usuwania. Domyślnie wykona je NA ŻYWO.
Jeżeli chcesz "suchy bieg" użyj parametru -WhatIf.

Uruchomienie:
  PowerShell (Administrator) > .\reset-to-clean-state.ps1 [-WhatIf]

Autorem skryptu jesteś Ty (Arek) — dostosowałem go do twoich wymagań.
#>

param(
    [switch]$WhatIf
)

Set-StrictMode -Version Latest

# --- Przygotowanie ścieżek i logowania ---
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptRoot) { $ScriptRoot = (Get-Location).Path }
$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$Global:LogPath = Join-Path $ScriptRoot "reset-log-$timestamp.txt"
$BackupRoot = Join-Path $ScriptRoot "backups\$timestamp"

function Write-Log {
    param([string]$Level, [string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    # print
    switch ($Level) {
        'ERROR'   { Write-Host $line -ForegroundColor Red }
        'WARN'    { Write-Host $line -ForegroundColor Yellow }
        'INFO'    { Write-Host $line -ForegroundColor Cyan }
        default   { Write-Host $line }
    }
    # append to file (always set)
    try { $line | Out-File -FilePath $Global:LogPath -Append -Encoding UTF8 -Force } catch {}
}

# Helper: run action respecting -WhatIf
function Safe-Run {
    param(
        [ScriptBlock]$Action,
        [string]$Description
    )

    if ($WhatIf) {
        Write-Log "INFO" "WHATIF: $Description"
    } else {
        try {
            & $Action
            Write-Log "INFO" "$Description - OK"
        }
        catch {
            Write-Log "ERROR" "$Description - $_"
        }
    }
}

Write-Log "INFO" "START skryptu. WhatIf=$WhatIf"
Write-Log "INFO" "ScriptRoot: $ScriptRoot"

# Utwórz folder backup jeśli real run
if (-not $WhatIf) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    Write-Log "INFO" "Backup root: $BackupRoot"
} else {
    Write-Log "INFO" "Symulacja: backup nie zostanie utworzony"
}

# Lista katalogów C:\Tools do usunięcia/backupu
$toolsToRemove = @('C:\Tools\Aria2','C:\Tools\yt-dlp','C:\Tools\ffmpeg','C:\Tools\Peace','C:\Tools\mpv','C:\Tools\vlc')

foreach ($t in $toolsToRemove) {
    if (Test-Path $t) {
        $desc = "Backup i usunięcie: $t"
        Safe-Run -Action { 
            # backup
            if (-not $WhatIf) {
                $dest = Join-Path $BackupRoot (Split-Path $t -Leaf)
                Copy-Item -Path $t -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue
            }
            # remove
            Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction Stop
        } -Description $desc
    } else {
        Write-Log "INFO" "Nie znaleziono katalogu: $t"
    }
}

# Usuń autostartowy skrót Aria2 (jeśli istnieje)
$StartupFolder = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$ariaShortcut = Join-Path $StartupFolder 'Aria2 AutoStart.lnk'
if (Test-Path $ariaShortcut) {
    Safe-Run -Action { Remove-Item -LiteralPath $ariaShortcut -Force } -Description "Usuwanie autostartu: $ariaShortcut"
} else { Write-Log "INFO" "Brak skrótu autostartu Aria2" }

# Usuń user config folders
$userConfigs = @(
    (Join-Path $env:USERPROFILE '.spotdl'),
    (Join-Path $env:USERPROFILE '.bandcamp-dl'),
    (Join-Path $env:USERPROFILE '.scdl'),
    (Join-Path $env:USERPROFILE '.config\yt-dlp'),
    (Join-Path $env:USERPROFILE '.config\aria2'),
    (Join-Path $env:USERPROFILE '.config\yt-dlp'),
    (Join-Path $env:USERPROFILE '.spotdl'),
    (Join-Path $env:USERPROFILE '.local\share\yt-dlp')
) | Select-Object -Unique

foreach ($c in $userConfigs) {
    if (Test-Path $c) {
        Safe-Run -Action {
            if (-not $WhatIf) {
                $dest = Join-Path $BackupRoot ('users_config_' + (Split-Path $c -Leaf))
                Copy-Item -Path $c -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue
            }
            Remove-Item -LiteralPath $c -Recurse -Force -ErrorAction Stop
        } -Description "Backup i usunięcie configu: $c"
    } else {
        Write-Log "INFO" "Nie znaleziono configu: $c"
    }
}

# Odinstaluj przez Chocolatey (jeśli obecny)
function Try-Choco-Uninstall {
    param([string[]]$packages)
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        foreach ($pkg in $packages) {
            Safe-Run -Action { choco uninstall $pkg -y } -Description "choco uninstall $pkg"
        }
    } else {
        Write-Log "INFO" "Chocolatey nie jest zainstalowany"
    }
}

# Odinstaluj przez winget
function Try-Winget-Uninstall {
    param([string[]]$packages)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        foreach ($pkg in $packages) {
            Safe-Run -Action { winget uninstall --id $pkg -e --silent } -Description "winget uninstall $pkg"
        }
    } else {
        Write-Log "INFO" "winget nie jest dostępny"
    }
}

$pkgs = @('yt-dlp','aria2','ffmpeg','vlc','mpv','peace','spotdl')
Try-Choco-Uninstall -packages $pkgs
# Winget often uses different ids; try common ids
$wingetIds = @('yt-dlp.yt-dlp','aria2.aria2','ffmpeg.ffmpeg','VLC.VLC','mpv.Mpv','Peace.Peace','spotdl.spotdl')
Try-Winget-Uninstall -packages $wingetIds

# Clean PATH: remove entries that point to C:\Tools and remove duplicates
function Clean-Path {
    Write-Log "INFO" "Analiza i czyszczenie PATH"
    $machinePath = [Environment]::GetEnvironmentVariable('PATH','Machine')
    $userPath = [Environment]::GetEnvironmentVariable('PATH','User')

    $splitMachine = $machinePath -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    $splitUser = $userPath -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    $filteredMachine = $splitMachine | Where-Object { $_ -notmatch '^C:\\\\?\\?Tools' -and $_ -notmatch '^C:\\Tools' }
    $filteredUser = $splitUser | Where-Object { $_ -notmatch '^C:\\\\?\\?Tools' -and $_ -notmatch '^C:\\Tools' }

    $uniqueMachine = $filteredMachine | Select-Object -Unique
    $uniqueUser = $filteredUser | Select-Object -Unique

    if (-not $WhatIf) {
        [Environment]::SetEnvironmentVariable('PATH', ($uniqueMachine -join ';'), 'Machine')
        [Environment]::SetEnvironmentVariable('PATH', ($uniqueUser -join ';'), 'User')
        Write-Log "INFO" "PATH zaktualizowany (usunięto wpisy C:\\Tools i duplikaty)"
        # backup ścieżek
        "$machinePath" | Out-File -FilePath (Join-Path $BackupRoot 'path_machine_backup.txt') -Encoding UTF8 -Force
        "$userPath" | Out-File -FilePath (Join-Path $BackupRoot 'path_user_backup.txt') -Encoding UTF8 -Force
    } else {
        Write-Log "INFO" "WHATIF: PATH nie zostanie zmieniony"
    }
}
Clean-Path

# Usuń aliasy/funkcje z profilu PowerShell (bez kasowania całego profilu)
function Clean-Profile-Aliases {
    $profilePath = $PROFILE
    if (-not (Test-Path $profilePath)) {
        Write-Log "INFO" "Brak profilu PowerShell: $profilePath"
        return
    }
    $content = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { Write-Log "WARN" "Profil jest pusty"; return }

    $patterns = @('function mp3yt','function zgrajspoti','function soundclouddl','function bandcampdl','function ytvideo','oh-my-posh','ChocolateyProfile')

    $new = $content
    foreach ($p in $patterns) {
        $regex = [regex]::Escape($p) + '.*?(?=(^function|^Set-Alias|^#|$))'
        try { $new = [regex]::Replace($new, $regex, '', [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) } catch {}
    }

    if ($new -ne $content) {
        Safe-Run -Action { Set-Content -LiteralPath $profilePath -Value $new -Encoding UTF8 -Force } -Description "Aktualizacja profilu PowerShell: usunięcie niestandardowych aliasów/funkcji"
    } else { Write-Log "INFO" "Profil PowerShell nie zawiera dopasowanych aliasów/funkcji" }
}
Clean-Profile-Aliases

# Usuń pliki tymczasowe i uszkodzone artefakty z katalogu skryptu (np. uszkodzone zip/exe pobrane)
function Clean-Script-Temp {
    $patternsToRemove = @('*.zip','*.exe.partial','*peace*','*peace-setup*')
    foreach ($pat in $patternsToRemove) {
        $files = Get-ChildItem -Path $ScriptRoot -Filter $pat -File -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            Safe-Run -Action { Copy-Item -Path $f.FullName -Destination (Join-Path $BackupRoot ('script_artifacts_backup')) -Force -ErrorAction SilentlyContinue; Remove-Item -LiteralPath $f.FullName -Force } -Description "Usuwanie artefaktu: $($f.Name)"
        }
    }
}
Clean-Script-Temp

# Tworzenie Security Log podsumowującego (w katalogu backup lub tylko symulacja)
function Create-SummaryLog {
    $logPath = if ($WhatIf) { Join-Path $ScriptRoot "reset-summary-whatif-$timestamp.txt" } else { Join-Path $BackupRoot "reset-summary-$timestamp.txt" }
    $summary = @()
    $summary += "Reset summary - $timestamp"
    $summary += "ScriptRoot: $ScriptRoot"
    $summary += "WhatIf: $WhatIf"
    $summary += "Backups: $BackupRoot"
    $summary += "Removed Tools: $($toolsToRemove -join ', ')"
    $summary += "User config removed: $($userConfigs -join ', ')"
    $summary | Out-File -FilePath $logPath -Encoding UTF8 -Force
    Write-Log "INFO" "Podsumowanie zapisane: $logPath"
}
Create-SummaryLog

Write-Log "INFO" "ZAKOŃCZENIE skryptu"

if ($WhatIf) { Write-Host "Symulacja zakończona. Jeśli wszystko wygląda OK, uruchom bez -WhatIf aby wykonać." -ForegroundColor Yellow }
else { Write-Host "Operacje wykonane. Sprawdź katalog backup: $BackupRoot i log: $Global:LogPath" -ForegroundColor Green }
