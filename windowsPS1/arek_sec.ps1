# WindowsToolkit - Security Module AREKBOX ORIGINAL
# Based on Developer Chaosu's ArekBox 2026

param([string]$Command = "menu")
$ErrorActionPreference = "Stop"

function Show-SecurityMenu {
    Clear-Host
    Write-Host "=== AREKBOX SECURITY MODULE ===" -ForegroundColor Red
    Write-Host ""
    Write-Host "[1] Invoke-Armor - Port Hardening"
    Write-Host "[2] Invoke-AbuseDispatcher - Auto Report Bots"
    Write-Host "[3] Repair-SystemMudd - Aggressive Cleanup"
    Write-Host "[4] PATH Security Audit"
    Write-Host "[5] Network Scanner"
    Write-Host ""
    Write-Host "[B] Back"
    Write-Host ""
}

function Invoke-Armor {
    Write-Host "`n=== INVOKE-ARMOR: CRITICAL PORT LOCKDOWN ===" -ForegroundColor Red
    
    $zombieServices = @("RemoteRegistry", "SharedAccess", "Fax", "Spooler")
    $criticalPorts = @(135, 139, 445, 3389, 5985, 5986)
    
    Write-Host "[*] Phase 1: Killing zombie services..." -ForegroundColor Yellow
    foreach ($svc in $zombieServices) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "[+] Neutralized: $svc" -ForegroundColor Green
        } catch {
            Write-Host "[!] $svc - already dead or not found" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n[*] Phase 2: Hardening critical ports..." -ForegroundColor Yellow
    foreach ($port in $criticalPorts) {
        $ruleName = "ArekBox_Armor_$port"
        try {
            Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
            New-NetFirewallRule -DisplayName $ruleName `
                -Direction Inbound `
                -LocalPort $port `
                -Protocol TCP `
                -Action Block `
                -Profile Any | Out-Null
            Write-Host "[+] Port $port: LOCKED" -ForegroundColor Green
        } catch {
            Write-Host "[!] Port $port: ERROR - $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`n[*] Phase 3: Disabling discovery protocols..." -ForegroundColor Yellow
    try {
        # Disable LLMNR
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0
        Write-Host "[+] LLMNR disabled" -ForegroundColor Green
        
        # Disable NetBIOS over TCP/IP
        $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'"
        foreach ($adapter in $adapters) {
            $adapter.SetTcpipNetbios(2) | Out-Null
        }
        Write-Host "[+] NetBIOS disabled" -ForegroundColor Green
        
    } catch {
        Write-Host "[!] Protocol disable error: $_" -ForegroundColor Red
    }
    
    Write-Host "`n[✓] ARMOR ACTIVATED - System hardened!" -ForegroundColor Green
}

function Invoke-AbuseDispatcher {
    Write-Host "`n=== INVOKE-ABUSEDISPATCHER: AUTOMATED REPORTING ===" -ForegroundColor Red
    
    Write-Host "[*] Scanning Event Log for failed auth attempts..." -ForegroundColor Yellow
    
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName='Security'
            ID=4625
        } -MaxEvents 500 -ErrorAction SilentlyContinue
        
        $attackers = @{}
        
        foreach ($event in $events) {
            if ($event.Message -match '\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b') {
                $ip = $matches[1]
                if ($attackers.ContainsKey($ip)) {
                    $attackers[$ip]++
                } else {
                    $attackers[$ip] = 1
                }
            }
        }
        
        $sorted = $attackers.GetEnumerator() | Sort-Object Value -Descending
        
        Write-Host "`n[+] Found $($sorted.Count) unique attackers" -ForegroundColor Green
        Write-Host "`nTop 10 offenders:" -ForegroundColor Cyan
        
        $top = $sorted | Select-Object -First 10
        foreach ($attacker in $top) {
            Write-Host "  $($attacker.Key): $($attacker.Value) attempts" -ForegroundColor Red
        }
        
        $report = Read-Host "`n[?] Generate abuse reports? (Y/N)"
        
        if ($report -eq 'Y') {
            $reportDir = "AbuseReports_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $reportDir | Out-Null
            
            foreach ($attacker in $top) {
                $ip = $attacker.Key
                $count = $attacker.Value
                
                $reportContent = @"
AUTOMATED ABUSE REPORT - AREKBOX 2026
=====================================

Attacking IP: $ip
Failed Auth Attempts: $count
Detection Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source System: $env:COMPUTERNAME
Domain: $env:USERDNSDOMAIN

DESCRIPTION:
This IP address has been identified performing brute-force authentication
attempts against our Windows system. Attack pattern suggests automated
botnet activity.

RECOMMENDED ACTION:
- Block IP at network perimeter
- Investigate source network for compromised hosts
- Add to threat intelligence feeds

REPORT TO:
- CERT Polska: cert@cert.pl
- NASK Abuse: abuse@nask.pl
- ISP Abuse Contact: (run whois $ip)

Generated by: ArekBox 2026 Security System
"@
                
                $filename = "$reportDir\abuse_$($ip.Replace('.','_')).txt"
                $reportContent | Out-File -FilePath $filename -Encoding UTF8
            }
            
            Write-Host "[+] Reports generated in: $reportDir" -ForegroundColor Green
            Write-Host "[*] Send to CERT/NASK manually or automate via email" -ForegroundColor Cyan
        }
        
    } catch {
        Write-Host "[!] Error accessing Event Log: $_" -ForegroundColor Red
        Write-Host "[*] Run as Administrator for full access" -ForegroundColor Yellow
    }
}

function Repair-SystemMudd {
    Write-Host "`n=== REPAIR-SYSTEMMUDD: AGGRESSIVE SYSTEM CLEANUP ===" -ForegroundColor Red
    Write-Host "[!] WARNING: This performs deep system modifications!" -ForegroundColor Yellow
    
    $confirm = Read-Host "[?] Continue with SystemMudd repair? (Type YES)"
    if ($confirm -ne "YES") {
        Write-Host "[!] Aborted" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n[*] Phase 1: Neutralizing telemetry services..." -ForegroundColor Yellow
    $telemetryServices = @(
        "DiagTrack",
        "dmwappushservice",
        "RetailDemo",
        "RemoteRegistry"
    )
    
    foreach ($svc in $telemetryServices) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "[+] Killed: $svc" -ForegroundColor Green
        } catch {
            Write-Host "[!] $svc - not found or already disabled" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n[*] Phase 2: Blocking telemetry domains..." -ForegroundColor Yellow
    $telemetryHosts = @(
        "vortex.data.microsoft.com",
        "vortex-win.data.microsoft.com",
        "telecommand.telemetry.microsoft.com",
        "oca.telemetry.microsoft.com",
        "sqm.telemetry.microsoft.com",
        "watson.telemetry.microsoft.com"
    )
    
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    $hostsContent = Get-Content $hostsFile -ErrorAction SilentlyContinue
    
    foreach ($domain in $telemetryHosts) {
        if ($hostsContent -notcontains "127.0.0.1 $domain") {
            Add-Content -Path $hostsFile -Value "127.0.0.1 $domain" -ErrorAction SilentlyContinue
            Write-Host "[+] Blocked: $domain" -ForegroundColor Green
        }
    }
    
    Write-Host "`n[*] Phase 3: Aggressive cleanup..." -ForegroundColor Yellow
    
    # Temp files
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
    Write-Host "[+] Temp files purged" -ForegroundColor Green
    
    # Windows Update cache
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Host "[+] Windows Update cache cleared" -ForegroundColor Green
    
    # DNS cache
    ipconfig /flushdns | Out-Null
    Write-Host "[+] DNS cache flushed" -ForegroundColor Green
    
    Write-Host "`n[*] Phase 4: Registry debloat..." -ForegroundColor Yellow
    
    # Disable Cortana
    $cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $cortanaPath)) {
        New-Item -Path $cortanaPath -Force | Out-Null
    }
    Set-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0 -ErrorAction SilentlyContinue
    Write-Host "[+] Cortana disabled" -ForegroundColor Green
    
    # Disable Windows Tips
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value 1 -ErrorAction SilentlyContinue
    Write-Host "[+] Windows Tips disabled" -ForegroundColor Green
    
    Write-Host "`n[✓] SYSTEMMUDD REPAIR COMPLETE!" -ForegroundColor Green
    Write-Host "[*] Recommend: Reboot system" -ForegroundColor Cyan
}

function Test-PathSecurity {
    Write-Host "`n=== PATH SECURITY AUDIT ===" -ForegroundColor Red
    
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User") -split ';'
    $systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine") -split ';'
    $allPaths = ($userPath + $systemPath) | Where-Object { $_ -ne "" }
    
    Write-Host "[*] Auditing PATH for security issues..." -ForegroundColor Yellow
    
    # Check 1: Duplicates
    Write-Host "`n[1] Duplicate PATH entries:" -ForegroundColor Cyan
    $duplicates = $allPaths | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($duplicates) {
        foreach ($dup in $duplicates) {
            Write-Host "  [!] '$($dup.Name)' appears $($dup.Count) times" -ForegroundColor Red
        }
    } else {
        Write-Host "  [+] No duplicates found" -ForegroundColor Green
    }
    
    # Check 2: Non-existent paths
    Write-Host "`n[2] Non-existent paths:" -ForegroundColor Cyan
    $invalid = $allPaths | Where-Object { -not (Test-Path $_) }
    if ($invalid) {
        foreach ($path in $invalid) {
            Write-Host "  [!] Dead path: $path" -ForegroundColor Red
        }
    } else {
        Write-Host "  [+] All paths valid" -ForegroundColor Green
    }
    
    # Check 3: Suspicious locations
    Write-Host "`n[3] Suspicious PATH locations:" -ForegroundColor Cyan
    $suspicious = @("Temp", "Public", "Downloads")
    $found = $allPaths | Where-Object {
        $path = $_
        $suspicious | Where-Object { $path -like "*$_*" }
    }
    if ($found) {
        foreach ($path in $found) {
            Write-Host "  [!] Risky: $path" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [+] No suspicious paths" -ForegroundColor Green
    }
    
    # Check 4: CRITICAL - Duplicate executables
    Write-Host "`n[4] CRITICAL: Duplicate .exe files:" -ForegroundColor Red
    $exeMap = @{}
    
    foreach ($path in ($allPaths | Where-Object { Test-Path $_ })) {
        Get-ChildItem -Path $path -Filter "*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
            if ($exeMap.ContainsKey($_.Name)) {
                $exeMap[$_.Name] += @($_.FullName)
            } else {
                $exeMap[$_.Name] = @($_.FullName)
            }
        }
    }
    
    $dupes = $exeMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    if ($dupes) {
        Write-Host "  [!!!] SECURITY RISK: Duplicate executables found!" -ForegroundColor Red
        foreach ($exe in $dupes) {
            Write-Host "`n  [!] $($exe.Key):" -ForegroundColor Yellow
            $exe.Value | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
        }
        Write-Host "`n  [!] WARNING: Wrong version may execute!" -ForegroundColor Red
        Write-Host "  [!] Potential malware hijacking vector!" -ForegroundColor Red
    } else {
        Write-Host "  [+] No duplicate executables" -ForegroundColor Green
    }
}

function Scan-NetworkPorts {
    Write-Host "`n=== NETWORK PORT SCANNER ===" -ForegroundColor Red
    
    $target = Read-Host "Target (IP/hostname, default: localhost)"
    if ([string]::IsNullOrWhiteSpace($target)) { $target = "localhost" }
    
    $commonPorts = @(
        @{Port=21; Name="FTP"},
        @{Port=22; Name="SSH"},
        @{Port=23; Name="Telnet"},
        @{Port=80; Name="HTTP"},
        @{Port=135; Name="RPC"},
        @{Port=139; Name="NetBIOS"},
        @{Port=443; Name="HTTPS"},
        @{Port=445; Name="SMB"},
        @{Port=3306; Name="MySQL"},
        @{Port=3389; Name="RDP"},
        @{Port=5985; Name="WinRM-HTTP"},
        @{Port=8080; Name="HTTP-Alt"}
    )
    
    Write-Host "[*] Scanning $target..." -ForegroundColor Yellow
    
    foreach ($p in $commonPorts) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $connect = $tcp.BeginConnect($target, $p.Port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(100, $false)
            
            if ($wait -and $tcp.Connected) {
                Write-Host "[OPEN] $($p.Port) - $($p.Name)" -ForegroundColor Red
                $tcp.Close()
            }
        } catch {}
    }
    
    Write-Host "[+] Scan complete" -ForegroundColor Green
}

# MAIN LOOP
if ($Command -eq "help") {
    Show-SecurityMenu
    return
}

while ($true) {
    Show-SecurityMenu
    $choice = Read-Host "Choose"
    
    switch ($choice) {
        '1' { Invoke-Armor }
        '2' { Invoke-AbuseDispatcher }
        '3' { Repair-SystemMudd }
        '4' { Test-PathSecurity }
        '5' { Scan-NetworkPorts }
        'B' { return }
        default { 
            Write-Host "[!] Invalid" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
    
    Write-Host ""
    Read-Host "Press Enter"
}
