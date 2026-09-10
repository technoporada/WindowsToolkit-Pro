<#
.SYNOPSIS
    System Health Combo Tool - SFC, DISM i CheckDisk.
.DESCRIPTION
    Automatyzuje proces naprawy obrazu systemu i plików systemowych.
#>

$Results = @{}

# 1. Sprawdzenie uprawnień
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Wymagane uprawnienia administratora."
    exit
}

# 2. Naprawa obrazu (DISM)
Write-Host "[1/3] Naprawa obrazu systemowego (DISM)..." -ForegroundColor Cyan
try {
    # Uzasadnienie: Cleanup-Image naprawia bazę komponentów przed skanowaniem plików SFC.
    $dism = DISM /Online /Cleanup-Image /RestoreHealth
    $Results['DISM'] = "Success"
} catch {
    $Results['DISM'] = "Failed"
}

# 3. Sprawdzanie plików systemowych (SFC)
Write-Host "[2/3] Weryfikacja plików systemowych (SFC)..." -ForegroundColor Cyan
$sfc = sfc /scannow
if ($sfc -match "found corrupt files and successfully repaired") {
    $Results['SFC'] = "Repaired"
} elseif ($sfc -match "did not find any integrity violations") {
    $Results['SFC'] = "Clean"
} else {
    $Results['SFC'] = "Issues found/Failed"
}

# 4. Diagnostyka dysku (Chkdsk - Read Only)
Write-Host "[3/3] Skanowanie dysku (ReadOnly)..." -ForegroundColor Cyan
# Uzasadnienie: Skanowanie bez flagi /f nie wymaga restartu, pozwala na wstępną diagnozę.
$chkdsk = chkdsk C:
if ($chkdsk -match "Windows has scanned the file system and found no problems") {
    $Results['Chkdsk'] = "Healthy"
} else {
    $Results['Chkdsk'] = "Errors detected - Action required: chkdsk /f"
}

# Raport końcowy
Write-Host "`n--- PODSUMOWANIE ---" -ForegroundColor Yellow
$Results.GetEnumerator() | Out-String
