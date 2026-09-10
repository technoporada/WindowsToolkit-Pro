<#
.SYNOPSIS
    System Pulse (H5N1 Edition) - Comprehensive System Diagnostic & Repair Tool.
    Philosophy: CBZC (Clean, Fast, Reliable).
.DESCRIPTION
    Replaces legacy 'Kombajn' scripts with modular, high-performance diagnostics.
#>

$ErrorActionPreference = "Stop"

function Get-PulseHeader {
    Clear-Host
    $Title = "--- SYSTEM PULSE [ECHO(NOSPACE)] ---"
    Write-Host "`n$Title" -ForegroundColor Cyan
    Write-Host "Machine: $($env:COMPUTERNAME) | User: $($env:USERNAME) | Date: $(Get-Date)" -ForegroundColor Gray
}

function Get-SystemMetrics {
    Write-Host "`n[1] METRYKI WYDAJNOŚCI" -ForegroundColor Yellow
    
    # CPU Usage (Quick Sample)
    $CPU = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty LoadPercentage
    # RAM Usage
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem
    $TotalRAM = [Math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
    $FreeRAM = [Math]::Round($OS.FreePhysicalMemory / 1MB, 2)
    $UsedRAM = $TotalRAM - $FreeRAM
    $RAMPercent = [Math]::Round(($UsedRAM / $TotalRAM) * 100, 2)

    Write-Host "  CPU Load:  $CPU %" -ForegroundColor (if($CPU -gt 80){"Red"}else{"Green"})
    Write-Host "  RAM Usage: $UsedRAM GB / $TotalRAM GB ($RAMPercent %)" -ForegroundColor (if($RAMPercent -gt 80){"Red"}else{"Green"})
}

function Get-StorageStatus {
    Write-Host "`n[2] STATUS MAGAZYNU" -ForegroundColor Yellow
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $Size = [Math]::Round($_.Size / 1GB, 2)
        $Free = [Math]::Round($_.FreeSpace / 1GB, 2)
        $UsedPercent = [Math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
        Write-Host "  Dysk $($_.DeviceID) : $UsedPercent % zajęte ($Free GB wolne z $Size GB)" -ForegroundColor (if($UsedPercent -gt 90){"Red"}else{"White"})
    }
}

function Get-SecurityBrief {
    Write-Host "`n[3] BEZPIECZEŃSTWO & USŁUGI" -ForegroundColor Yellow
    $Defender = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    $Ollama = Get-NetTCPConnection -LocalPort 11434 -ErrorAction SilentlyContinue | Select-Object -First 1

    $DefStatus = if($Defender) { $Defender.Status } else { "NOT INSTALLED" }
    $OlStatus = if($Ollama) { "RUNNING" } else { "NOT ACTIVE" }

    Write-Host "  Windows Defender: $DefStatus" -ForegroundColor (if($DefStatus -eq "Running"){"Green"}else{"Yellow"})
    Write-Host "  Ollama Service:   $OlStatus" -ForegroundColor (if($OlStatus -eq "Running"){"Green"}else{"Gray"})
}

function Invoke-NetworkReset {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "`n[!] BŁĄD: Reset sieci wymaga uprawnień Administratora." -ForegroundColor Red
        return
    }

    Write-Host "`n[!] RESETOWANIE SIECI (WINSOCK/DNS/IP)..." -ForegroundColor Cyan
    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null
    ipconfig /flushdns | Out-Null
    Write-Host "  Sieć zresetowana pomyślnie." -ForegroundColor Green
}

# --- EXECUTION ---
Get-PulseHeader
Get-SystemMetrics
Get-StorageStatus
Get-SecurityBrief

Write-Host "`n--- OPCJE ---" -ForegroundColor Gray
Write-Host "R - Reset Sieci (Wymaga Admina) | Q - Wyjście" -ForegroundColor Cyan

$Key = Read-Host "`nWybierz akcję"
if ($Key -eq "R") { Invoke-NetworkReset; pause }
