# ===============================================
# ECHO(NOSPACE) - PS1 COLLECTION COCKPIT
# Philosophy: CBZC (Chcemy Być Zajebiście Czysti)
# ===============================================
Write-Host "
--- SYSTEM COCKPIT [H5N1] ---" -ForegroundColor Cyan

function Show-Menu {
    Write-Host "1. AREK-Kombajn V3 (Global Repair/Net/DX)" -ForegroundColor Yellow
    Write-Host "2. Firewall Manager (Rules/Log/Monitor)" -ForegroundColor Yellow
    Write-Host "3. Environment Repair (PATH/DevTools)" -ForegroundColor Yellow
    Write-Host "4. System Optimizer (Debloat/Cleanup)" -ForegroundColor Yellow
    Write-Host "5. Dev Setup (Python/Node/WSL)" -ForegroundColor Yellow
    Write-Host "Q. Wyjdź (Exit)" -ForegroundColor Red
}

do {
    Show-Menu
    $choice = Read-Host "
Wybierz opcję"
    switch ($choice) {
        '1' { powershell -ExecutionPolicy Bypass -File "05_System_Repair\System-Pulse.ps1" }
        '2' { powershell -ExecutionPolicy Bypass -File "02_Security_Firewall\FirewallManager2.ps1" }
        '3' { powershell -ExecutionPolicy Bypass -File "05_System_Repair\check_and_fix_path.ps1" }
        '4' { powershell -ExecutionPolicy Bypass -File "01_Optimization_Debloat\system-optimizer.ps1" }
        '5' { Get-ChildItem "04_Dev_Environment" | Format-Table Name, Extension }
        'Q' { break }
        default { Write-Host "Nie kumam bazy. Wybierz 1-5 lub Q." -ForegroundColor Red }
    }
} while ($true)
