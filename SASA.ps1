# 1. Definicja ścieżek
$CbsLog = "$env:windir\Logs\CBS\CBS.log"
$DesktopReport = "$env:userprofile\Desktop\Raport_Bledow_SFC.txt"

Write-Host "Analizuję logi systemowe... Proszę czekać." -ForegroundColor Cyan

# 2. Wyciąganie tylko konkretnych błędów [SR] (System Repair)
if (Test-Path $CbsLog) {
    # Filtrujemy linie, gdzie SFC mówi "nie mogę naprawić"
    Select-String -Path $CbsLog -Pattern "\[SR\] Cannot repair member file", "\[SR\] Could not reproject corrupted file" | 
        ForEach-Object { $_.Line } > $DesktopReport

    if ((Get-Item $DesktopReport).Length -gt 0) {
        Write-Host "Zrobione! Lista uszkodzonych plików jest w: $DesktopReport" -ForegroundColor Yellow
        Write-Host "Otwieram plik..."
        notepad $DesktopReport
    } else {
        Write-Host "Logi nie zawierają jawnych błędów [SR]. Problem może leżeć w rejestrze." -ForegroundColor Green
    }
} else {
    Write-Error "Nie znaleziono pliku logów CBS."
}
