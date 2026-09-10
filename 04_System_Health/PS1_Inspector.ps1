# =====================================
# PS1_Inspector.ps1  (wersja poprawiona)
# Sprawdza skladnie PS1 bez wywolywania PowerShell -Command
# =====================================

param (
    [string]$RootFolder = "$PSScriptRoot"
)

$logFolder = Join-Path $RootFolder "syntax_logs"
if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder | Out-Null }

# 1. Sprawdzanie skladni PS1
Get-ChildItem -Path $RootFolder -Filter *.ps1 -Recurse | ForEach-Object {
    $file = $_.FullName
    Write-Output "Sprawdzanie skladni: $file"

    try {
        $null = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
        Add-Content -Path (Join-Path $logFolder "ps_syntax_ok.log") -Value $file
    }
    catch {
        Add-Content -Path (Join-Path $logFolder "ps_syntax_errors.log") -Value "$file : $_"
    }
}

# 2. Lista funkcji
Get-ChildItem -Path $RootFolder -Filter *.ps1 -Recurse | ForEach-Object {
    Select-String -Path $_.FullName -Pattern "function\s+(\w+)" |
        ForEach-Object { $_.Matches[0].Groups[1].Value }
} | Sort-Object | Get-Unique | Set-Content (Join-Path $logFolder "ps_functions_list.txt")

# 3. Polecenia instalacyjne
$patterns = @("choco install", "winget install", "Install-Package")
Get-ChildItem -Path $RootFolder -Filter *.ps1 -Recurse | ForEach-Object {
    $file = $_.FullName
    foreach ($p in $patterns) {
        $matches = Select-String -Path $file -Pattern $p
        if ($matches) {
            $matches | ForEach-Object { "$file : $_" } | 
                Add-Content (Join-Path $logFolder "package_installs.log")
        }
    }
}

Write-Output "Raport gotowy w katalogu: $logFolder"
