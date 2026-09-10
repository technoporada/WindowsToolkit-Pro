# Pobierz podstawowe informacje o systemie operacyjnym
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
# Pobierz informacje o procesorze
$cpuInfo = Get-CimInstance -ClassName Win32_Processor
# Pobierz informacje o pamięci RAM
$ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
# Pobierz informacje o karcie graficznej
$gpuInfo = Get-CimInstance -ClassName Win32_VideoController
# Pobierz informacje o dysku twardym
$diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}

# Wyświetl informacje o systemie operacyjnym
Write-Host "Informacje o Systemie Operacyjnym:" -ForegroundColor Green
Write-Host "  Nazwa: $($osInfo.Caption)"
Write-Host "  Wersja: $($osInfo.Version)"
Write-Host "  Architektura: $($osInfo.OSArchitecture)"
Write-Host "  Numer kompilacji: $($osInfo.BuildNumber)"
Write-Host "  Katalog Windows: $($osInfo.WindowsDirectory)"

# Wyświetl informacje o procesorze
Write-Host "`nInformacje o Procesorze:" -ForegroundColor Green
Write-Host "  Model: $($cpuInfo.Name)"
Write-Host "  Architektura: $($cpuInfo.Architecture)"
Write-Host "  Liczba rdzeni: $($cpuInfo.NumberOfCores)"
Write-Host "  Liczba procesorów logicznych: $($cpuInfo.NumberOfLogicalProcessors)"

# Wyświetl informacje o pamięci RAM
Write-Host "`nInformacje o Pamięci RAM:" -ForegroundColor Green
Write-Host "  Całkowita pamięć: $($ramInfo.Sum / 1GB) GB"

# Wyświetl informacje o karcie graficznej
Write-Host "`nInformacje o Karcie Graficznej:" -ForegroundColor Green
foreach ($gpu in $gpuInfo) {
    Write-Host "  Nazwa: $($gpu.Name)"
    Write-Host "  Pamięć: $($gpu.AdapterRAM / 1MB) MB"
    Write-Host "  Sterownik: $($gpu.DriverVersion)"
}

# Wyświetl informacje o dysku twardym
Write-Host "`nInformacje o Dysku Twardym:" -ForegroundColor Green
foreach ($disk in $diskInfo) {
    Write-Host "  Nazwa: $($disk.DeviceID)"
    Write-Host "  Pojemność: $([math]::Round($disk.Capacity / 1GB, 2)) GB"
    Write-Host "  Wolne miejsce: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB"
    Write-Host "  System plików: $($disk.FileSystem)"
}
