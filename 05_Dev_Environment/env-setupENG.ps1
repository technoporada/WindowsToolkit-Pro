# env-setup-ps5.ps1
# Interaktywny setup Windows dev environment - PS5-compatible ASCII-only
# Run as Administrator:
# Set-ExecutionPolicy Bypass -Scope Process
# .\env-setup-ps5.ps1

function Ask-YesNo {
    param([string]$q, [string]$d='n')
    $ans = Read-Host "$q (y/n) [default $d]"
    if ([string]::IsNullOrWhiteSpace($ans)) { $ans = $d }
    return $ans.ToLower().StartsWith('y')
}

function Safe-Write { param([string]$t) Write-Host $t }

# check admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Run PowerShell as Administrator and re-run this script." -ForegroundColor Red
    exit 1
}

Safe-Write "=== ENV-SETUP (PS5) START ==="
Safe-Write ("Date: " + (Get-Date).ToString())

# 1) Restore point (optional)
if (Ask-YesNo "Create system restore point now? (recommended)" "y") {
    try {
        Checkpoint-Computer -Description "Before env-setup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "Restore point created." -ForegroundColor Green
    } catch {
        Write-Host ("Failed to create restore point: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

# 2) Scan: Appx, Services, PATH, Listening ports
Write-Host "`n--- SCAN: Appx, Services, PATH, Listening Ports ---" -ForegroundColor Cyan

# Appx packages
try {
    $apps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object Name, PackageFullName, InstallLocation
} catch {
    $apps = @()
}
if ($apps -and $apps.Count -gt 0) {
    Write-Host "`nAppx packages found:" -ForegroundColor Green
    $i = 0
    foreach ($a in $apps) {
        Write-Host ("[{0}] {1}" -f $i, $a.Name)
        $i++
    }
} else {
    Write-Host "`nNo Appx packages found or insufficient permissions." -ForegroundColor Yellow
}

# Services of interest
$servicesCheck = @("DiagTrack","WSearch","W32Time","dmwappushservice","WpnService")
Write-Host "`nServices of interest:" -ForegroundColor Green
foreach ($s in $servicesCheck) {
    try {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) { Write-Host ("{0,-20} : {1}" -f $svc.Name, $svc.Status) } else { Write-Host ("{0,-20} : NotFound" -f $s) }
    } catch {
        Write-Host ("{0,-20} : Error" -f $s)
    }
}

# PATH entries (Machine)
Write-Host "`nPATH (Machine-level):" -ForegroundColor Green
$pathRaw = [Environment]::GetEnvironmentVariable("PATH","Machine")
$parts = @()
if ($pathRaw) { $parts = $pathRaw -split ';' | Where-Object { $_ -and $_ -ne '' } }
$idx = 0
foreach ($p in $parts) {
    $exists = $false
    try { $exists = Test-Path $p } catch { $exists = $false }
    if ($exists) { $status = "Exists" } else { $status = "Missing" }
    Write-Host ("[{0}] {1} -> {2}" -f $idx, $p, $status)
    $idx++
}

# Listening TCP ports
Write-Host "`nListening TCP ports (may require privileges):" -ForegroundColor Green
try {
    $tcp = Get-NetTCPConnection -State Listen -ErrorAction Stop | Select-Object LocalAddress, LocalPort -Unique
    if ($tcp -and $tcp.Count -gt 0) { $tcp | Format-Table -AutoSize } else { Write-Host "No listening ports or insufficient permissions." -ForegroundColor Yellow }
} catch {
    Write-Host ("Cannot list listening ports: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 3) Backup PATH + dedupe (interactive)
if (Ask-YesNo "`nMake backup of Machine PATH and remove duplicates/missing entries? (safe option)" "y") {
    $backupFile = Join-Path $env:TEMP ("path-backup-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $parts | Out-File -FilePath $backupFile -Encoding ASCII
    Write-Host ("Saved PATH backup to: {0}" -f $backupFile)
    # keep existing entries first, then missing
    $keepExisting = @()
    $keepMissing = @()
    foreach ($p in $parts) {
        if (Test-Path $p) { if (-not ($keepExisting -contains $p)) { $keepExisting += $p } }
        else { if (-not ($keepMissing -contains $p)) { $keepMissing += $p } }
    }
    $keep = $keepExisting + $keepMissing
    Write-Host "`nPATH preview (existing first):"
    foreach ($k in $keep) { Write-Host (" - {0}" -f $k) }
    if (Ask-YesNo "Write new PATH to Machine environment? (apply changes)" "n") {
        $newPath = $keep -join ';'
        try {
            [Environment]::SetEnvironmentVariable("PATH",$newPath,"Machine")
            Write-Host "PATH updated." -ForegroundColor Green
        } catch {
            Write-Host ("Failed to set PATH: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        }
    } else {
        Write-Host "Skipped PATH update."
    }
}

# 4) Winget installs (interactive)
Write-Host "`n--- Winget: install tools (PowerShell7, Terminal, Notepad++, Git) ---" -ForegroundColor Cyan
if (Ask-YesNo "Use winget to install tools? (requires winget and internet)" "y") {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCmd) {
        Write-Host "winget not found. Install App Installer from Microsoft Store or get winget manually." -ForegroundColor Yellow
    } else {
        $choices = @(
            @{ id=0; name='PowerShell'; pkg='Microsoft.PowerShell' },
            @{ id=1; name='Windows Terminal'; pkg='Microsoft.WindowsTerminal' },
            @{ id=2; name='Notepad++'; pkg='Notepad++' },
            @{ id=3; name='Git'; pkg='Git.Git' },
            @{ id=4; name='Visual Studio Code'; pkg='Microsoft.VisualStudioCode' }
        )
        Write-Host "Available packages:"
        foreach ($c in $choices) { Write-Host ("[{0}] {1}" -f $c.id, $c.name) }
        $sel = Read-Host "Enter indexes to install (comma separated) or Enter to skip"
        if (-not [string]::IsNullOrWhiteSpace($sel)) {
            $idxs = $sel -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
            foreach ($i in $idxs) {
                $choice = $choices | Where-Object { $_.id -eq $i }
                if ($choice) {
                    Write-Host ("Installing: {0} (attempt)" -f $choice.name)
                    try {
                        # best-effort: try install by name
                        winget install --silent --accept-source-agreements --accept-package-agreements --name "$($choice.name)" -e
                        Write-Host ("winget: install attempted for {0}" -f $choice.name) -ForegroundColor Green
                    } catch {
                        Write-Host ("winget install failed for {0}: {1}" -f $choice.name, $_.Exception.Message) -ForegroundColor Yellow
                    }
                }
            }
        } else {
            Write-Host "Skipped winget installs."
        }
    }
}

# 5) Profile PowerShell: add aliases to CurrentUserAllHosts
if (Ask-YesNo "`nAdd simple aliases to PowerShell CurrentUserAllHosts profile (lista,katalog)?" "y") {
    $profileFile = $PROFILE.CurrentUserAllHosts
    try {
        if (-not (Test-Path $profileFile)) { New-Item -Path $profileFile -ItemType File -Force | Out-Null }
        $content = @'
# Simple aliases for convenience
if (-not (Get-Alias -Name lista -ErrorAction SilentlyContinue)) { Set-Alias lista Get-ChildItem }
if (-not (Get-Alias -Name katalog -ErrorAction SilentlyContinue)) { Set-Alias katalog Set-Location }
Write-Host "Local PS profile loaded."
'@
        Add-Content -Path $profileFile -Value $content
        Write-Host ("Profile updated: {0}" -f $profileFile) -ForegroundColor Green
    } catch {
        Write-Host ("Failed to update profile: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

# 6) WSL (optional)
if (Ask-YesNo "`nInstall WSL features (requires restart)? (optional)" "n") {
    try {
        Write-Host "Enabling WSL and VirtualMachinePlatform (no restart forced)."
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
        Write-Host "WSL features enabled. You may need to restart." -ForegroundColor Green
        if (Ask-YesNo "Install Ubuntu distribution via wsl --install -d Ubuntu now? (attempt)" "n") {
            try { wsl --install -d Ubuntu } catch { Write-Host ("WSL install attempt failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        }
    } catch {
        Write-Host ("WSL enable failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

# 7) Firewall hardening (interactive)
if (Ask-YesNo "`nAdd firewall rules to block common ports (RPC/SMB/RDP/WinRM)? (optional)" "n") {
    $ports = @(135,445,3389,5985)
    foreach ($p in $ports) {
        try {
            $name = "BLOCK_PORT_$p"
            $exists = Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue
            if (-not $exists) {
                New-NetFirewallRule -DisplayName $name -Direction Inbound -LocalPort $p -Protocol TCP -Action Block -Profile Any
                Write-Host ("Rule added: {0}" -f $name) -ForegroundColor Green
            } else {
                Write-Host ("Rule already exists: {0}" -f $name)
            }
        } catch {
            Write-Host ("Failed to add rule for port {0}: {1}" -f $p, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
    Write-Host "Note: blocking ports can break RDP, printing, SMB, etc." -ForegroundColor Yellow
}

# 8) Telemetry services (optional stop/disable)
if (Ask-YesNo "`nStop and disable selected telemetry services (DiagTrack, dmwappushservice, WpnService)? (optional)" "n") {
    $tele = @("DiagTrack","dmwappushservice","WpnService")
    foreach ($t in $tele) {
        try {
            $svc = Get-Service -Name $t -ErrorAction SilentlyContinue
            if ($svc) {
                Stop-Service -Name $t -Force -ErrorAction SilentlyContinue
                Set-Service -Name $t -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Host ("Service {0} stopped and disabled." -f $t) -ForegroundColor Green
            } else {
                Write-Host ("Service {0} not found." -f $t)
            }
        } catch {
            Write-Host ("Cannot change {0}: {1}" -f $t, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
    Write-Host "Note: Windows Update or OEM tools may re-enable these services." -ForegroundColor Yellow
}

# 9) Generate apply/undo scripts (console-driven)
if (Ask-YesNo "`nGenerate apply/undo ps1 for selected Appx/services/Path (files saved to %TEMP%)?" "n") {
    $remApps = @()
    if ($apps -and $apps.Count -gt 0) {
        Write-Host "`nEnter indexes of Appx packages to remove (comma separated) or Enter to skip."
        $i = 0
        foreach ($a in $apps) { Write-Host ("[{0}] {1}" -f $i, $a.Name); $i++ }
        $sel = Read-Host "Appx indexes:"
        if (-not [string]::IsNullOrWhiteSpace($sel)) {
            $idxs = $sel -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
            foreach ($k in $idxs) { if ($k -ge 0 -and $k -lt $apps.Count) { $remApps += $apps[$k].Name } }
        }
    }

    # services to disable input
    $remSvcs = @()
    Write-Host "`nEnter service names to disable (comma separated) or Enter to skip (example: DiagTrack,WSearch):"
    $svcInput = Read-Host "Services:"
    if (-not [string]::IsNullOrWhiteSpace($svcInput)) { $remSvcs = $svcInput -split ',' | ForEach-Object { $_.Trim() } }

    # path indices to remove
    $remPaths = @()
    Write-Host "`nEnter PATH indices to remove (from above list), comma separated, or Enter to skip."
    $pathInput = Read-Host "PATH indices:"
    if (-not [string]::IsNullOrWhiteSpace($pathInput)) {
        $idxs = $pathInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
        foreach ($k in $idxs) { if ($k -ge 0 -and $k -lt $parts.Count) { $remPaths += $parts[$k] } }
    }

    # build apply script (ASCII)
    $apply = "# apply.ps1 - generated by env-setup`n# Run as Administrator`n`n"
    foreach ($a in $remApps) {
        $apply += ("Try { Get-AppxPackage -AllUsers -Name ""{0}"" | Remove-AppxPackage -ErrorAction SilentlyContinue; Write-Output 'REMOVED: {0}' } Catch { Write-Output 'FAILED: {0}' }`n" -f $a)
    }
    foreach ($s in $remSvcs) {
        $apply += ("Try { Stop-Service -Name ""{0}"" -Force -ErrorAction SilentlyContinue; Set-Service -Name ""{0}"" -StartupType Disabled -ErrorAction SilentlyContinue; Write-Output 'SERVICE DISABLED: {0}' } Catch { Write-Output 'SERVICE FAILED: {0}' }`n" -f $s)
    }
    if ($remPaths.Count -gt 0) {
        $apply += "`n# Remove PATH entries`n$old = [Environment]::GetEnvironmentVariable('PATH','Machine')`n$parts = $old -split ';' | Where-Object { $_ -and $_ -ne '' }`n"
        foreach ($rp in $remPaths) {
            $escaped = $rp.Replace('"','""')
            $apply += ('$parts = $parts | Where-Object { $_ -ne "{0}" }' -f $escaped) + "`n"
        }
        $apply += "[Environment]::SetEnvironmentVariable('PATH',($parts -join ';'),'Machine')`nWrite-Output 'PATH updated'`n"
    }

    # build undo script (best-effort, ASCII)
    $undo = "# undo.ps1 - generated by env-setup`n# Note: app reinstall may require Store/DISM`n`n"
    foreach ($s in $remSvcs) {
        $undo += ("Try { Set-Service -Name ""{0}"" -StartupType Manual -ErrorAction SilentlyContinue; Write-Output 'SERVICE ENABLED: {0}' } Catch { Write-Output 'SERVICE FAILED: {0}' }`n" -f $s)
    }
    if ($remPaths.Count -gt 0) {
        $undo += "`n# Append removed PATH entries back (best-effort)`n$old = [Environment]::GetEnvironmentVariable('PATH','Machine')`n$parts = $old -split ';' | Where-Object { $_ -and $_ -ne '' }`n"
        foreach ($rp in $remPaths) {
            $escaped = $rp.Replace('"','""')
            $undo += ('$parts += "{0}"' -f $escaped) + "`n"
        }
        $undo += "[Environment]::SetEnvironmentVariable('PATH',($parts -join ';'),'Machine')`nWrite-Output 'PATH restored (appended)'`n"
    }

    $tmpApply = Join-Path $env:TEMP ("apply-{0}.ps1" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $tmpUndo  = Join-Path $env:TEMP ("undo-{0}.ps1" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    try {
        $apply | Out-File -FilePath $tmpApply -Encoding ASCII -Force
        $undo  | Out-File -FilePath $tmpUndo  -Encoding ASCII -Force
        Write-Host ("Apply script: {0}" -f $tmpApply)
        Write-Host ("Undo script : {0}" -f $tmpUndo)
        Write-Host "Inspect files before running. Run manually in PowerShell as Administrator."
    } catch {
        Write-Host ("Failed to write apply/undo scripts: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

Safe-Write "`n=== ENV-SETUP: FINISHED ===`n"
