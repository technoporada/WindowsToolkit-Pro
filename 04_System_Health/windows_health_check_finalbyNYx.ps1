<#
windows_health_check_final.ps1
NyX - final Windows-only health check (PowerShell 7+)
Uruchom w pwsh jako Administrator.
#>

param(
    [string[]]$Sections = @("SystemInfo","Disks","LargestFiles","TopProcesses","StartupItems","InstalledPrograms","Services","FirewallNetwork","Defender","WindowsUpdate","EventErrors"),
    [int]$JobTimeout = 8,                  # timeout w sekundach dla SafeJob (podnieś jeśli masz wolny system)
    [string]$OutJson = ".\win_health_report.json",
    [string]$OutHtml = ".\win_health_report.html",
    [string]$OutRec = ".\recommendations.json"
)

# --- Helpers ---
function Write-Log { param($s) Write-Output ("[{0}] {1}" -f (Get-Date -Format "s"), $s) }

function SafeJob {
    param(
        [ScriptBlock]$Script,
        [int]$TimeoutSeconds = $using:JobTimeout
    )
    try {
        $job = Start-Job -ScriptBlock $Script
        if (Wait-Job -Job $job -Timeout $TimeoutSeconds) {
            $res = Receive-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            return $res
        } else {
            Stop-Job -Job $job -Force -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            return [PSCustomObject]@{ Timeout = "$TimeoutSeconds s" }
        }
    } catch {
        return [PSCustomObject]@{ Error = "SafeJob error: $_" }
    }
}

function Ensure-Admin {
    try {
        $isElevated = ([Security.Principal.WindowsIdentity]::GetCurrent()).Groups -match "S-1-5-32-544"
        if (-not $isElevated) {
            Write-Warning "Nie jesteś Administratorem. Uruchom pwsh jako Administrator dla pełnych danych."
        }
    } catch {
        Write-Warning "Nie udało się sprawdzić uprawnień admin: $_"
    }
}

# --- Sekcje ---
function Section-SystemInfo {
    try {
        $os = SafeJob { Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue } $JobTimeout
        $cs = SafeJob { Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue } $JobTimeout
        $bootTime = $null
        try { if ($os -and $os.LastBootUpTime) { $bootTime = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime) } } catch { $bootTime = $null }
        $uptime = if ($bootTime) { (Get-Date) - $bootTime } else { $null }
        return [PSCustomObject]@{
            Hostname = $env:COMPUTERNAME
            OS = if($os -and $os.Caption) { "$($os.Caption) $($os.Version) Build $($os.BuildNumber)" } else { "Unknown" }
            Architecture = if($os -and $os.OSArchitecture) { $os.OSArchitecture } else { $null }
            Uptime = $uptime
            Manufacturer = if($cs -and $cs.Manufacturer) { $cs.Manufacturer } else { $null }
            Model = if($cs -and $cs.Model) { $cs.Model } else { $null }
        }
    } catch { return [PSCustomObject]@{ Error = "SystemInfo error: $_" } }
}

function Section-Disks {
    try {
        $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue
        $out = @()
        foreach ($d in $drives) {
            try {
                $free = $d.Free
                $used = $d.Used
                $usedPercent = if ($used -and $free) { [math]::Round(($used/($used+$free)*100),2) } else { $null }
                $out += [PSCustomObject]@{ Name=$d.Name; Root=$d.Root; Free=$free; Used=$used; UsedPercent=$usedPercent }
            } catch { $out += [PSCustomObject]@{ Name=$d.Name; Error="Drive error: $_" } }
        }
        return $out
    } catch { return [PSCustomObject]@{ Error = "Disks error: $_" } }
}

function Section-LargestFiles {
    param($Path="C:\",$MinMB=100)
    try {
        return Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue -Force |
            Where-Object { -not $_.PSIsContainer } |
            Select-Object FullName,@{Name='SizeMB';Expression={[math]::Round($_.Length/1MB,2)}} |
            Where-Object { $_.SizeMB -ge $MinMB } |
            Sort-Object SizeMB -Descending |
            Select-Object -First 50
    } catch { return @() }
}

function Section-TopProcesses {
    try {
        return Get-Process -ErrorAction SilentlyContinue |
            Select-Object Id,ProcessName,@{Name='CPU';Expression={$_.CPU}},@{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet/1MB,2)}} |
            Sort-Object CPU -Descending |
            Select-Object -First 15
    } catch { return @() }
}

function Section-StartupItems {
    $startup = @()
    try {
        $paths = @(
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) {
                Get-ChildItem -Path $p -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    $startup += [PSCustomObject]@{ Source="StartupFolder"; Path=$p; Item=$_.FullName }
                }
            }
        }
        $runKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
        )
        foreach ($rk in $runKeys) {
            if (Test-Path $rk) {
                try {
                    $props = Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue
                    foreach ($p in ($props | Get-Member -MemberType NoteProperty)) {
                        $name = $p.Name
                        $val = (Get-ItemProperty -Path $rk -Name $name -ErrorAction SilentlyContinue).$name
                        $startup += [PSCustomObject]@{ Source="Registry"; Key=$rk; Name=$name; Command=$val }
                    }
                } catch {}
            }
        }
        $tasks = SafeJob { Get-ScheduledTask -ErrorAction SilentlyContinue } $JobTimeout
        if ($tasks -is [System.Array]) {
            foreach ($t in $tasks) {
                try {
                    if ($t.Triggers -match "AtLogon") { $startup += [PSCustomObject]@{ Source="ScheduledTask"; TaskName=$t.TaskName; Path=$t.TaskPath } }
                } catch {}
            }
        }
    } catch { $startup += [PSCustomObject]@{ Error = "StartupItems error: $_" } }
    return $startup
}

function Section-InstalledPrograms {
    $list = @()
    try {
        $regs = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        foreach ($r in $regs) {
            if (Test-Path $r) {
                Get-ChildItem $r -ErrorAction SilentlyContinue | ForEach-Object {
                    try {
                        $p = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
                        if ($p.DisplayName) {
                            $list += [PSCustomObject]@{
                                Name = $p.DisplayName; Version = $p.DisplayVersion; Publisher = $p.Publisher; InstallDate = $p.InstallDate; UninstallString = $p.UninstallString
                            }
                        }
                    } catch {}
                }
            }
        }
    } catch {}
    return $list | Sort-Object Name -Unique
}

function Section-Services {
    try { return Get-Service -ErrorAction SilentlyContinue | Select-Object Name,DisplayName,Status,StartType } catch { return @() }
}

function Section-FirewallNetwork {
    try {
        $fw = SafeJob { Get-NetFirewallRule -ErrorAction SilentlyContinue | Select-Object Name,DisplayName,Direction,Action,Enabled,Profile } $JobTimeout
        $ports = SafeJob { Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess } $JobTimeout
        $listening = @()
        if ($ports -is [System.Array]) {
            foreach ($p in $ports) {
                try {
                    $proc = Get-Process -Id $p.OwningProcess -ErrorAction SilentlyContinue
                    $pName = if ($proc) { $proc.ProcessName } else { "Unknown" }
                    $listening += [PSCustomObject]@{ LocalAddress=$p.LocalAddress; LocalPort=$p.LocalPort; Process=$pName }
                } catch { $listening += [PSCustomObject]@{ LocalAddress=$p.LocalAddress; LocalPort=$p.LocalPort; Process="Unknown" } }
            }
        } else {
            $listening = $ports
        }
        return [PSCustomObject]@{ FirewallRules=$fw; Listening=$listening }
    } catch { return [PSCustomObject]@{ Error="FirewallNetwork error: $_" } }
}

function Section-Defender {
    try {
        $status = SafeJob { Get-MpComputerStatus -ErrorAction SilentlyContinue } $JobTimeout
        if ($status -and $status.PSObject.Properties.Name -contains 'AMRunning') {
            return [PSCustomObject]@{
                AMRunning = $status.AntispywareEnabled
                AVRunning = $status.AntivirusEnabled
                SignatureVersion = $status.AntivirusSignatureVersion
                LastQuickScan = $status.LastQuickScanTime
                LastFullScan = $status.LastFullScanTime
            }
        } else {
            return [PSCustomObject]@{ Note = "Get-MpComputerStatus niedostępne lub brak uprawnień" }
        }
    } catch { return [PSCustomObject]@{ Error="Defender error: $_" } }
}

function Section-WindowsUpdate {
    try {
        $res = SafeJob {
            try {
                $s = New-Object -ComObject Microsoft.Update.Session
                $searcher = $s.CreateUpdateSearcher()
                $searcher.QueryHistory(0,50) | Select-Object Date,Title,ResultCode
            } catch { @{ Error = "COM error" } }
        } $JobTimeout
        return $res
    } catch { return @{ Note = "WindowsUpdate error" } }
}

function Section-EventErrors {
    try {
        $res = SafeJob { Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 50 -ErrorAction SilentlyContinue | Select-Object TimeCreated,Id,LevelDisplayName,Message } $JobTimeout
        return $res
    } catch { return @() }
}

# --- Run selected sections ---
Ensure-Admin
$report = [ordered]@{ CollectedAt = (Get-Date).ToString("s"); Results = @{} }

foreach ($s in $Sections) {
    Write-Log "Uruchamiam sekcję: $s"
    try {
        switch ($s) {
            "SystemInfo"      { $report.Results.SystemInfo = Section-SystemInfo }
            "Disks"           { $report.Results.Disks = Section-Disks }
            "LargestFiles"    { $report.Results.LargestFiles = Section-LargestFiles -Path "C:\" -MinMB 100 }
            "TopProcesses"    { $report.Results.TopProcesses = Section-TopProcesses }
            "StartupItems"    { $report.Results.StartupItems = Section-StartupItems }
            "InstalledPrograms"{ $report.Results.InstalledPrograms = Section-InstalledPrograms }
            "Services"        { $report.Results.Services = Section-Services }
            "FirewallNetwork" { $report.Results.FirewallNetwork = Section-FirewallNetwork }
            "Defender"        { $report.Results.Defender = Section-Defender }
            "WindowsUpdate"   { $report.Results.WindowsUpdate = Section-WindowsUpdate }
            "EventErrors"     { $report.Results.EventErrors = Section-EventErrors }
            Default           { Write-Warning "Nieznana sekcja: $s" }
        }
    } catch { $report.Results.$s = [PSCustomObject]@{ Error = "Sekcja $s przerwana: $_" } }
}

# --- Simple recommendations (heurystyki) ---
$recs = @()
try {
    $diskC = $report.Results.Disks | Where-Object { $_.Name -eq 'C' } | Select-Object -First 1
    if ($diskC -and $diskC.UsedPercent -and ($diskC.UsedPercent -gt 85)) {
        $recs += [PSCustomObject]@{ Item="Dysk C"; Issue="Zapełnienie >85%"; Action="Oczyść temp, przenieś duże pliki"; Risk="Medium" }
    }
} catch {}
try {
    if ($report.Results.Defender -and $report.Results.Defender.AVRunning -ne $true) {
        $recs += [PSCustomObject]@{ Item="Antywirus"; Issue="Defender nieaktywny"; Action="Sprawdź zainstalowane AV, uruchom skan"; Risk="High" }
    }
} catch {}
try {
    if ($report.Results.LargestFiles -and ($report.Results.LargestFiles | Measure-Object).Count -gt 0) {
        $recs += [PSCustomObject]@{ Item="Duże pliki"; Issue="Znaleziono pliki >=100MB"; Action="Sprawdź i przenieś/usun"; Risk="Low" }
    }
} catch {}

# --- Zapis plików ---
try {
    $report | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutJson -Encoding UTF8
    Write-Log "Zapisano JSON: $OutJson"
} catch { Write-Warning "Nie udało się zapisać JSON: $_" }

try {
    $html = "<html><head><meta charset='utf-8'><title>Win Health Report</title></head><body><h1>Win Health Report</h1><pre>$($report | Out-String)</pre></body></html>"
    $html | Out-File -FilePath $OutHtml -Encoding UTF8
    Write-Log "Zapisano HTML: $OutHtml"
} catch { Write-Warning "Nie udało się zapisać HTML: $_" }

try {
    $recs | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutRec -Encoding UTF8
    Write-Log "Zapisano recommendations: $OutRec"
} catch { Write-Warning "Nie udało się zapisać recommendations: $_" }

Write-Log "Zakończono. Sprawdź pliki: $OutJson, $OutHtml, $OutRec"
