# ===============================================
# Windows Environment Cleanup (Safe)
# PowerShell 5.1+
# ===============================================

$Host.UI.RawUI.ForegroundColor = "White"

function Write-Info($msg) { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-ErrorMsg($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Success($msg) { Write-Host "[OK]    $msg" -ForegroundColor Green }

# ---- BACKUP PATH ----
$backupPathFile = "$env:USERPROFILE\PATH_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$env:Path | Out-File -FilePath $backupPathFile -Encoding UTF8
Write-Info "PATH backup saved to $backupPathFile"

# ---- ANALIZA PATH ----
$pathElements = $env:Path -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
$duplicates = $pathElements | Group-Object | Where-Object {$_.Count -gt 1} | Select-Object -ExpandProperty Name

if ($duplicates) {
    Write-Warn "Duplicate PATH entries found:"
    $duplicates | ForEach-Object { Write-Host "  $($_)" }
} else {
    Write-Success "No duplicate PATH entries found"
}

# ---- ZNAJDŹ PROGRAMY ----
$programs = @{
    "Choco" = "choco.exe"
    "Winget" = "winget.exe"
    "Python" = "python.exe"
    "Node" = "node.exe"
    "npm" = "npm.cmd"
    "Git" = "git.exe"
    "PowerShell" = "powershell.exe"
}

$foundPrograms = @{}

foreach ($prog in $programs.GetEnumerator()) {
    $path = (Get-Command $prog.Value -ErrorAction SilentlyContinue).Path
    if ($path) {
        Write-Success "$($prog.Key) found at $path"
        $foundPrograms[$prog.Key] = $path
    } else {
        Write-Warn "$($prog.Key) not found in PATH"
    }
}

# ---- WSKAŹ STARE INSTALACJE ----
$checkDirs = @(
    "$env:ProgramFiles",
    "$env:ProgramFiles(x86)",
    "$env:LOCALAPPDATA",
    "$env:USERPROFILE\AppData\Local",
    "$env:USERPROFILE\AppData\Roaming"
)

$oldInstalls = @()
foreach ($dir in $checkDirs) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "Python|Node|npm|Git|chocolatey|PowerShell" } |
            ForEach-Object { 
                Write-Warn "Found old installation: $($_.FullName)"
                $oldInstalls += $_.FullName
            }
    }
}

# ---- INTERAKTYWNE CZYSZCZENIE PATH ----
$removeDuplicates = Read-Host "Remove duplicate PATH entries? (y/n)"
if ($removeDuplicates -match '^[Yy]$') {
    $newPath = $pathElements | Select-Object -Unique
    [Environment]::SetEnvironmentVariable("Path", ($newPath -join ";"), "User")
    Write-Success "Duplicates removed. Current PATH:"
    $newPath
}

# ---- INTERAKTYWNE USUWANIE STARYCH INSTALACJI ----
if ($oldInstalls.Count -gt 0) {
    $removeOld = Read-Host "Delete old installations detected? (y/n)"
    if ($removeOld -match '^[Yy]$') {
        foreach ($item in $oldInstalls) {
            try {
                Rename-Item -Path $item -NewName "$($item)_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -ErrorAction Stop
                Write-Success "Renamed $item (backup created)"
            } catch {
                Write-ErrorMsg "Failed to rename $item : $_"
            }
        }
    } else {
        Write-Info "Old installations not removed"
    }
} else {
    Write-Success "No old installations found for cleanup"
}

# ---- RAPORT KOŃCOWY ----
$reportFile = "$env:USERPROFILE\CleanupReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

@"
Cleanup Report - $(Get-Date)
-----------------------------
PATH backup: $backupPathFile
Duplicate PATH entries removed: $($removeDuplicates -match '^[Yy]$')
Old installations renamed: $($removeOld -match '^[Yy]$')
Detected old installations:
$($oldInstalls -join "`n")
Found programs:
$(foreach ($k in $foundPrograms.Keys) { "$k : $($foundPrograms[$k])" })
"@ | Out-File -FilePath $reportFile -Encoding UTF8

Write-Success "Cleanup complete! Report saved to $reportFile"
