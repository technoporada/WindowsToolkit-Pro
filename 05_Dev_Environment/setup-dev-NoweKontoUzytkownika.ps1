<#
.SYNOPSIS
    Tworzy nowe konto użytkownika z środowiskiem dev (wersja PL).
.PARAMETER NewUserName
    Nazwa użytkownika. Domyślnie: devuser
#>
param(
    [string]$NewUserName = "devuser"
)

Write-Host "Podaj hasło dla użytkownika $NewUserName:" -ForegroundColor Cyan
$NewUserPassword = Read-Host -AsSecureString

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewUserPassword)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

Write-Host "Tworzę użytkownika: $NewUserName" -ForegroundColor Yellow
net user $NewUserName $plainPassword /add
net localgroup "Administrators" $NewUserName /add

$plainPassword = $null

$packages = @(
    "Python.Python.3.12",
    "OpenJS.NodeJS.LTS",
    "Git.Git",
    "Microsoft.VisualStudioCode"
)

foreach ($pkg in $packages) {
    Write-Host "Instalacja $pkg..."
    winget install --id=$pkg --accept-source-agreements --accept-package-agreements --silent
}

Write-Host "`n✅ Gotowe! Użytkownik $NewUserName gotowy." -ForegroundColor Green
