$logFolder = "$PSScriptRoot\syntax_logs"
if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder }

# PowerShell - funkcje
Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 | ForEach-Object {
    Select-String -Path $_.FullName -Pattern "function\s+(\w+)" | ForEach-Object {
        $_.Matches[0].Groups[1].Value
    }
} | Sort-Object | Get-Unique | Set-Content "$logFolder\ps_functions_list.txt"

# Python - funkcje
Get-ChildItem -Path $PSScriptRoot -Filter *.py | ForEach-Object {
    Select-String -Path $_.FullName -Pattern "def\s+(\w+)" | ForEach-Object {
        $_.Matches[0].Groups[1].Value
    }
} | Sort-Object | Get-Unique | Set-Content "$logFolder\py_functions_list.txt"

Write-Output "Lista funkcji w $logFolder"
