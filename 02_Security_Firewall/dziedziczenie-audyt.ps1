<#
.SYNOPSIS
  Audyt NTFS (ACL) dla podanych ścieżek / dysków. Wyniki (CSV + error log) zapisane
  w tym samym katalogu co skrypt.
.DESCRIPTION
  Uruchom skrypt z katalogu, w którym chcesz mieć wyniki (np. D:\windowsPS1).
  Przykład:
    .\dziedziczenie-audyt.ps1 -Paths C:\,D:\ -IncludeShares -MaxDepth 3
.PARAMETER Paths
  Tablica ścieżek do przeskanowania (np. C:\, D:\Projects). Jeśli pusta -> wszystkie dyski logiczne.
.PARAMETER IncludeShares
  Jeżeli podane, skrypt dołączy nazwy udostępnień SMB (jeśli dostępne) przypisanych do danej ścieżki.
.PARAMETER MaxDepth
  Maksymalna głębokość rekurencji (0 = tylko podana ścieżka). Domyślnie: -1 (bez limitu).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string[]]$Paths = @(),

    [switch]$IncludeShares,

    [int]$MaxDepth = -1
)

# Ustal katalog na wyniki - katalog skryptu lub bieżący katalog
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
if (-not (Test-Path $scriptDir)) {
    New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
}

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$csvPath = Join-Path -Path $scriptDir -ChildPath "ACL_Audit_$timestamp.csv"
$errorLog = Join-Path -Path $scriptDir -ChildPath "ACL_Audit_Errors_$timestamp.log"

# Nagłówek CSV
$header = 'Folder,SMBShares,Owner,Group,Inheritance,AccessIdentity,AccessRights,AccessType,IsInherited'
Out-File -FilePath $csvPath -Encoding UTF8 -Force -InputObject $header

# Pobierz lista dysków jeśli nie podano Paths
if (-not $Paths -or $Paths.Count -eq 0) {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -ne $null } 
    $Paths = $drives.Root
}

# Pobierz wszystkie udziały SMB (jeśli potrzebne)
$allShares = @()
if ($IncludeShares) {
    try {
        $allShares = Get-SmbShare -ErrorAction Stop
    } catch {
        # Niektóre edycje Windows mogą nie mieć Get-SmbShare - logujemy i kontynuujemy
        Add-Content -Path $errorLog -Value "$(Get-Date) - WARN: Get-SmbShare niedostępne lub błąd: $($_.Exception.Message)"
        $allShares = @()
    }
}

# Funkcja: rekursywne przejście katalogu z limitem głębokości
function Get-FoldersRecursive {
    param(
        [Parameter(Mandatory=$true)][string]$RootPath,
        [int]$MaxDepth = -1
    )

    # Normalizacja
    $rootPath = (Convert-Path -LiteralPath $RootPath) -replace '\\+$','\'

    $stack = @()
    $stack += @{ Path = $rootPath; Depth = 0 }

    while ($stack.Count -gt 0) {
        $item = $stack[-1]
        $stack = $stack[0..($stack.Count-2)]

        $p = $item.Path
        $d = $item.Depth

        # Zwroc aktualny folder
        [PSCustomObject]@{ FullName = $p; Depth = $d }

        # Jeśli mamy limit głębokości i już go osiągnęliśmy => nie pushuj dalej
        if ($MaxDepth -ge 0 -and $d -ge $MaxDepth) { continue }

        # Pobierz podkatalogi
        try {
            $children = Get-ChildItem -LiteralPath $p -Directory -Force -ErrorAction Stop
            foreach ($c in $children) {
                $stack += @{ Path = $c.FullName; Depth = ($d + 1) }
            }
        } catch {
            # Brak dostępu lub inne błędy - logujemy i pomijamy
            Add-Content -Path $errorLog -Value "$(Get-Date) - WARN: Nie można enumerować $p : $($_.Exception.Message)"
            continue
        }
    }
}

# Funkcja: przetwórz pojedynczy folder i dopisz linie do CSV
function Process-Folder {
    param(
        [Parameter(Mandatory=$true)][string]$FolderPath,
        [array]$SharesForDrive
    )

    try {
        $acl = Get-Acl -LiteralPath $FolderPath -ErrorAction Stop
    } catch {
        Add-Content -Path $errorLog -Value "$(Get-Date) - ERR: Nie można pobrać ACL dla $FolderPath : $($_.Exception.Message)"
        return
    }

    $inheritance = if ($acl.AreAccessRulesProtected) { "Disabled" } else { "Enabled" }
    $sharesStr = ""
    if ($IncludeShares -and $SharesForDrive -and $SharesForDrive.Count -gt 0) {
        $sharesStr = ($SharesForDrive | Where-Object { $_.Path -and $_.Path.ToLower().StartsWith($FolderPath.ToLower()) } | Select-Object -ExpandProperty Name) -join ';'
        if (-not $sharesStr) {
            # Spróbuj przypisać shares dla całego dysku (np. C:\)
            $sharesStr = ($SharesForDrive.Name -join ';')
        }
    }

    foreach ($ace in $acl.Access) {
        $identity = $ace.IdentityReference.ToString()
        $rights = $ace.FileSystemRights.ToString()
        $atype = $ace.AccessControlType.ToString()
        $isInherited = $ace.IsInherited

        # Escape CSV
        $escapedFolder = '"' + ($FolderPath -replace '"','""') + '"'
        $escapedShares = '"' + ($sharesStr -replace '"','""') + '"'
        $escapedOwner = '"' + ($acl.Owner -replace '"','""') + '"'
        $escapedGroup = '"' + ($acl.Group -replace '"','""') + '"'
        $escapedIdentity = '"' + ($identity -replace '"','""') + '"'
        $escapedRights = '"' + ($rights -replace '"','""') + '"'
        $escapedType = '"' + ($atype -replace '"','""') + '"'
        $escapedInherited = '"' + ($isInherited.ToString() -replace '"','""') + '"'
        $escapedInheritance = '"' + ($inheritance -replace '"','""') + '"'

        $line = "$escapedFolder,$escapedShares,$escapedOwner,$escapedGroup,$escapedInheritance,$escapedIdentity,$escapedRights,$escapedType,$escapedInherited"
        Add-Content -Path $csvPath -Value $line
    }
}

# --- Główna pętla ---
foreach ($p in $Paths) {
    try {
        $resolved = Convert-Path -LiteralPath $p
    } catch {
        Add-Content -Path $errorLog -Value "$(Get-Date) - ERR: Ścieżka nie istnieje: $p"
        continue
    }

    Write-Host "Rozpoczynam skan: $resolved" -ForegroundColor Cyan

    # Jeżeli IncludeShares jest włączone - filtru shares dla dysku / ścieżki
    $sharesForDrive = @()
    if ($IncludeShares -and $allShares) {
        # wybierz shares, których Path zaczyna się od root (np. C:\)
        $sharesForDrive = $allShares | Where-Object { $_.Path -and ($resolved.ToLower().StartsWith(($_.Path.ToLower()) -replace '\\+$','\') -or ($_.Path.ToLower().StartsWith((Split-Path $resolved -Qualifier).ToLower()))) }
        if ($sharesForDrive.Count -eq 0) {
            # próbujemy prościej: shares na tej samej literze dysku
            $driveLetter = ([regex]::Match($resolved, '^[A-Za-z]:')).Value
            if ($driveLetter) {
                $sharesForDrive = $allShares | Where-Object { $_.Path -and ($_.Path.ToLower().StartsWith($driveLetter.ToLower())) }
            }
        }
    }

    # Iterate through folders (root + subfolders)
    $foldersEnum = Get-FoldersRecursive -RootPath $resolved -MaxDepth $MaxDepth
    $count = ($foldersEnum | Measure-Object).Count
    $i = 0
    foreach ($f in $foldersEnum) {
        $i++
        if ($i % 200 -eq 0) {
            Write-Progress -Activity "Skanowanie $resolved" -Status "$i / $count" -PercentComplete (($i/$count)*100)
        }
        Process-Folder -FolderPath $f.FullName -SharesForDrive $sharesForDrive
    }
}

Write-Host "`nAudyt zakonczony." -ForegroundColor Green
Write-Host "CSV: $csvPath" -ForegroundColor Yellow
if (Test-Path $errorLog) { Write-Host "Log bledow: $errorLog" -ForegroundColor Yellow }
