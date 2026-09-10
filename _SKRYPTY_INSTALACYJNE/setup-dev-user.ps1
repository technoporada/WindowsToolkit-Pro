<#
.SYNOPSIS
    Tworzy nowe konto użytkownika dev i instaluje środowisko programistyczne.
.DESCRIPTION
    Skrypt tworzy nowe konto Windows, instaluje Python, Node.js, Git, VS Code.
    Hasło jest pytane od użytkownika (nie jest hardkodowane).
.PARAMETER NewUserName
    Nazwa nowego użytkownika. Domyślnie: devuser
.EXAMPLE
    .\setup-dev-user.ps1
    .\setup-dev-user.ps1 -NewUserName "arek"
#>
param(
    [string]$NewUserName = "devuser"
)

# Pytaj o hasło bezpiecznie
Write-Host "Podaj hasło dla użytkownika $NewUserName:" -ForegroundColor Cyan
$NewUserPassword = Read-Host -AsSecureString

# Konwersja do plain text tylko do komendy net (potem wyczyść)
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewUserPassword)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

# 1. Tworzenie nowego użytkownika
Write-Host "Tworzę nowego użytkownika: $NewUserName" -ForegroundColor Yellow
net user $NewUserName $plainPassword /add
if ($LASTEXITCODE -ne 0) {
    Write-Host "BŁĄD: Nie udało się utworzyć użytkownika!" -ForegroundColor Red
    exit 1
}
net localgroup "Administrators" $NewUserName /add
Write-Host "✅ Użytkownik $NewUserName utworzony" -ForegroundColor Green

# Wyczyść hasło z pamięci
$plainPassword = $null

# 2. Instalacja narzędzi przez winget
$packages = @(
    "Python.Python.3.12",
    "OpenJS.NodeJS.LTS",
    "Git.Git",
    "Microsoft.VisualStudioCode"
)

Write-Host "`nInstaluję narzędzia developerskie..." -ForegroundColor Yellow
foreach ($pkg in $packages) {
    Write-Host "  Instalacja $pkg..." -NoNewline
    winget install --id=$pkg --accept-source-agreements --accept-package-agreements --silent 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ⚠️ (może już zainstalowane)" -ForegroundColor Yellow
    }
}

# 3. Podsumowanie
Write-Host "`n=== PODSUMOWANIE ===" -ForegroundColor Cyan
Write-Host "Python:  $(python --version 2>&1)" -ForegroundColor Gray
Write-Host "Node.js: $(node --version 2>&1)" -ForegroundColor Gray
Write-Host "Git:     $(git --version 2>&1)" -ForegroundColor Gray
Write-Host "`n✅ Gotowe! Zaloguj się jako $NewUserName" -ForegroundColor Green
