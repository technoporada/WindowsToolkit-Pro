$logFile = Join-Path $PSScriptRoot "validation_results.txt"
"--- RAPORT WALIDACJI SKRYPTÓW PS1 ---" | Out-File $logFile
"Data: $(Get-Date)" | Add-Content $logFile
"" | Add-Content $logFile

$files = Get-ChildItem -Path . -Filter *.ps1 -Recurse

foreach ($file in $files) {
    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    
    if ($errors) {
        "❌ BŁĄD SKŁADNI: $($file.FullName)" | Add-Content $logFile
        foreach ($err in $errors) {
            "   - $($err.Message) (Linia: $($err.Extent.StartLineNumber))" | Add-Content $logFile
        }
        "------------------------------------" | Add-Content $logFile
    } else {
        "✅ OK: $($file.FullName)" | Add-Content $logFile
    }
}

Write-Output "Walidacja zakończona. Wyniki zapisano w: $logFile"
