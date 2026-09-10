# directx-repair.ps1
$OutputEncoding = [System.Text.Encoding]::UTF8 # Ensure proper display of Polish characters
function Repair-DirectX {
    Write-Host "🎮 NAPRAWA DIRECTX..." -ForegroundColor Cyan
    
    # 1. Pobierz DirectX End-User Runtime
    $dxWebSetup = "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
    $dxFile = "$env:TEMP\directx_redist.exe"
    
    Invoke-WebRequest -Uri $dxWebSetup -OutFile $dxFile
    
    # 2. Wypakuj
    Start-Process $dxFile -ArgumentList "/Q /T:`"$env:TEMP\dxsetup`"" -Wait
    
    # 3. Zainstaluj
    $dxSetup = "$env:TEMP\dxsetup\DXSETUP.exe"
    if (Test-Path $dxSetup) {
        Start-Process $dxSetup -ArgumentList "/silent" -Wait
    }
    
    # 4. Sprawdź instalację
    $d3dFiles = @(
        "$env:SystemRoot\System32\d3dx9_43.dll",
        "$env:SystemRoot\System32\d3dx10_43.dll", 
        "$env:SystemRoot\System32\d3dx11_43.dll",
        "$env:SystemRoot\System32\xinput1_4.dll"
    )
    
    foreach ($file in $d3dFiles) {
        if (Test-Path $file) {
            Write-Host "✅ $((Get-Item $file).Name)" -ForegroundColor Green
        } else {
            Write-Host "❌ Brakuje: $((Split-Path $file -Leaf))" -ForegroundColor Red
        }
    }
}
