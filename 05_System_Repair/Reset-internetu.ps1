# Uruchamiaj jako Administrator!

# 1. Włączenie dziennika zdarzeń
wevtutil el | Foreach-Object {wevtutil cl "$_"}

# 2. Sprawdzenie i naprawa plików systemowych
sfc /scannow

# 3. Naprawa komponentów Windows Update (czasem na Win7 problematyczne)
net stop wuauserv
net stop bits
Remove-Item /s /q "%windir%\SoftwareDistribution"
net start wuauserv
net start bits

# 4. Resetowanie ustawień Winsock (sieć)
netsh winsock reset
netsh int ip reset
ipconfig /flushdns
ipconfig /release
ipconfig /renew

# 5. Wyczyść katalog temp
Remove-Item -Path "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue

# 6. Włącz usługi systemowe
Set-Service -Name wuauserv -StartupType Automatic
Set-Service -Name bits -StartupType Automatic
Set-Service -Name EventLog -StartupType Automatic

# 7. Czyszczenie niepotrzebnych plików systemowych
cleanmgr /sagerun:1

# 8. Restart po zakończeniu (opcjonalnie)
Write-Host "Naprawa zakończona. Czy chcesz zrestartować komputer? [T/N]"
$response = Read-Host
if ($response -eq "T") { Restart-Computer -Force }
