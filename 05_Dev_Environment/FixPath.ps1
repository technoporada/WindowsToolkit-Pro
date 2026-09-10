# --------------------------
# FixPath.ps1 - czyszczenie PATH
# --------------------------

# Backup starego PATH
$OldPath = $env:Path
$BackupFile = "$env:USERPROFILE\PathBackup.txt"
$OldPath | Out-File -Encoding UTF8 $BackupFile

# Rozdziel PATH na elementy
$raw = $env:Path -split ';'

# Hashset do de-dupe
$seen = @{}
$clean = New-Object System.Collections.Generic.List[string]

foreach ($p in $raw) {
    $trim = $p.Trim()
    if ($trim -and -not $seen.ContainsKey($trim)) {
        $seen[$trim] = $true
        $clean.Add($trim)
    }
}

# Usuń stare Pythony i nadmiarowe PowerShell
$final = New-Object System.Collections.Generic.List[string]

foreach ($p in $clean) {
    if ($p -match "Python" -and $p -notmatch "Python312") { continue }
    if ($p -match "PowerShell" -and $p -notmatch "PowerShell\\7") { continue }
    $final.Add($p)
}

# Dodaj Pythona i PowerShell 7 na początku w dobrej kolejności
$ordered = @(
    "C:\Windows\system32",
    "C:\Windows",
    "C:\Windows\System32\Wbem",
    "C:\Windows\System32\WindowsPowerShell\v1.0\",
    "C:\Windows\System32\OpenSSH\",
    "C:\Program Files\PowerShell\7\",
    "C:\Program Files\Git\cmd",
    "C:\Program Files\nodejs\",
    "C:\Program Files\Microsoft VS Code\bin",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python312\",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python312\Scripts\",
    "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Links"
)

# Połącz w jeden string i ustaw w bieżącej sesji
$env:Path = ($ordered -join ';')

# Minimalny output
"PATH został wyczyszczony i ustawiony w bieżącej sesji."
"Backup starego PATH zapisany w: $BackupFile"
$env:Path
