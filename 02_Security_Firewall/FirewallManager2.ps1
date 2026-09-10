# FirewallManager2.ps1
# Requires admin
# Idempotentny manager Windows Firewall - bez duplikatów, z logowaniem i monitoringiem
# Autor: NyX-style Auto-tool
# Usage: Save as FirewallManager2.ps1 and run in Admin PowerShell
# ---------------------------------------------------------------
# Uwaga: ten skrypt używa modułów NetSecurity (wbudowany w Windows)
# ---------------------------------------------------------------

# Require admin
# Requires -RunAsAdministrator

# Config
$Global:FWLogPath = Join-Path $env:USERPROFILE 'firewall-log.csv'
$Global:FWMonitorJobName = 'FW-Monitor-Job'
$Global:FWMonitorIntervalSec = 10

function Write-FwLog {
    param(
        [Parameter(Mandatory=$true)][string]$Action,
        [string]$Details = ''
    )
    $entry = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString('s')
        Action    = $Action
        Details   = $Details
        User      = $env:USERNAME
        Host      = $env:COMPUTERNAME
    }
    if (-not (Test-Path $Global:FWLogPath)) {
        "Timestamp,Action,Details,User,Host" | Out-File -FilePath $Global:FWLogPath -Encoding UTF8
    }
    $entryLine = "$($entry.Timestamp),$($entry.Action),`"$($entry.Details)`",$($entry.User),$($entry.Host)"
    $entryLine | Out-File -FilePath $Global:FWLogPath -Append -Encoding UTF8
}

function Get-FwRuleMatches {
    <#
    .SYNOPSIS
      Znajduje reguły firewall które pasują do parametrów (port/ip/program/direction/action)
    .PARAMETER LocalPort
    .PARAMETER RemoteAddress
    .PARAMETER Program
    .PARAMETER Direction
    .PARAMETER Action
    .OUTPUTS
      NetFirewallRule objects (with filters joined)
    #>
    param(
        [int[]]$LocalPort,
        [string[]]$RemoteAddress,
        [string]$Program,
        [ValidateSet('Inbound','Outbound')][string]$Direction,
        [ValidateSet('Allow','Block')][string]$Action
    )

    # Get all rules first (faster to filter in memory)
    $rules = Get-NetFirewallRule -ErrorAction SilentlyContinue
    if (-not $rules) { return @() }

    $matched = @()

    foreach ($r in $rules) {
        $portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue
        $addrFilter = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue
        $progFilter = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue

        $match = $true

        if ($LocalPort) {
            if (-not $portFilter) { $match = $false }
            else {
                # portFilter.LocalPort can be "80,443" or "Any"
                $portsRaw = $portFilter.LocalPort -join ','
                $hasPort = $false
                foreach ($p in $LocalPort) {
                    if ($portsRaw -match 'Any' -or $portsRaw -match "\b$p\b") { $hasPort = $true; break }
                }
                if (-not $hasPort) { $match = $false }
            }
        }

        if ($RemoteAddress -and $match) {
            if (-not $addrFilter) { $match = $false }
            else {
                $addrRaw = $addrFilter.RemoteAddress -join ','
                $hasAddr = $false
                foreach ($a in $RemoteAddress) {
                    if ($addrRaw -match 'Any' -or $addrRaw -match [regex]::Escape($a)) { $hasAddr = $true; break }
                }
                if (-not $hasAddr) { $match = $false }
            }
        }

        if ($Program -and $match) {
            if (-not $progFilter) { $match = $false }
            else {
                $prog = $progFilter.Program -join ','
                if ($prog -notmatch [regex]::Escape($Program)) { $match = $false }
            }
        }

        if ($Direction -and $match) {
            if ($r.Direction -ne $Direction) { $match = $false }
        }

        if ($Action -and $match) {
            if ($r.Action -ne $Action) { $match = $false }
        }

        if ($match) {
            # attach filters for convenience
            $r | Add-Member -NotePropertyName PortFilter -NotePropertyValue $portFilter -Force
            $r | Add-Member -NotePropertyName AddressFilter -NotePropertyValue $addrFilter -Force
            $r | Add-Member -NotePropertyName AppFilter -NotePropertyValue $progFilter -Force
            $matched += $r
        }
    }

    return $matched
}

function Test-FwRuleExists {
    <#
    .SYNOPSIS
      Sprawdza czy istnieje reguła odpowiadająca parametrom.
    .PARAMETER Name - display name exact match (optional)
    .PARAMETER LocalPort - int lub tablica
    .PARAMETER RemoteAddress - string lub tablica
    .PARAMETER Program - ścieżka do programu (exact albo contains)
    .PARAMETER Direction - Inbound/Outbound
    .PARAMETER Action - Allow/Block
    #>
    param(
        [string]$Name,
        [int[]]$LocalPort,
        [string[]]$RemoteAddress,
        [string]$Program,
        [ValidateSet('Inbound','Outbound')][string]$Direction,
        [ValidateSet('Allow','Block')][string]$Action
    )

    if ($Name) {
        $byName = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
        if ($byName) { return $true }
    }

    $matches = Get-FwRuleMatches -LocalPort $LocalPort -RemoteAddress $RemoteAddress -Program $Program -Direction $Direction -Action $Action
    return ($matches.Count -gt 0)
}

function Ensure-FwRule {
    <#
    .SYNOPSIS
      Idempotentnie tworzy regułę jeśli taka nie istnieje.
    .PARAMETER Name - DisplayName użyty do identyfikacji
    .PARAMETER LocalPort - pojedynczy port lub port range ("8000-8999" akceptowane jako string)
    .PARAMETER RemoteAddress - lista adresów / CIDR
    .PARAMETER Program - ścieżka programu
    .PARAMETER Direction - Inbound/Outbound
    .PARAMETER Action - Allow/Block
    .PARAMETER Description - dodatkowy tag/komentarz (użyj np. Tag:DEV)
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$false)][Object]$LocalPort,
        [string[]]$RemoteAddress = @('Any'),
        [string]$Program = $null,
        [ValidateSet('Inbound','Outbound')][string]$Direction = 'Inbound',
        [ValidateSet('Allow','Block')][string]$Action = 'Block',
        [string]$Description = ''
    )

    # Normalize LocalPort for matching: accept int[] or string range
    $lpForMatch = @()
    if ($LocalPort) {
        if ($LocalPort -is [string]) {
            # if format '8000-8999' expand a bit for matching single ports search
            $lpForMatch = @($LocalPort)
        } elseif ($LocalPort -is [int[]] -or $LocalPort -is [int]) {
            $lpForMatch = $LocalPort
        }
    }

    # Check if rule exists (by Name OR by parameters)
    $exists = $false
    if (Test-FwRuleExists -Name $Name -LocalPort $lpForMatch -RemoteAddress $RemoteAddress -Program $Program -Direction $Direction -Action $Action) {
        Write-Host "Reguła '$Name' już istnieje — pomijam tworzenie." -ForegroundColor Yellow
        Write-FwLog -Action "Ensure-Skipped" -Details "RuleExists: $Name"
        $exists = $true
    }

    if (-not $exists) {
        try {
            $params = @{
                DisplayName = $Name
                Direction   = $Direction
                Action      = $Action
                Enabled     = 'True'
                Profile     = 'Any'
            }

            if ($LocalPort) {
                # LocalPort param accepts string like "8000-8999" or "3000"
                $params.LocalPort = $LocalPort
                $params.Protocol = 'TCP'
            }
            if ($RemoteAddress) {
                $params.RemoteAddress = ($RemoteAddress -join ',')
            }
            if ($Program) {
                # Program-based rules are Application rules - use -Program
                $params.Program = $Program
            }
            if ($Description) {
                $params.Description = $Description
            }

            # Create the rule
            New-NetFirewallRule @params -ErrorAction Stop | Out-Null
            Write-Host "Dodano regułę: $Name" -ForegroundColor Green
            Write-FwLog -Action "Add-Rule" -Details "$Name;Ports:$LocalPort;Addr:$($RemoteAddress -join ',');Prog:$Program;Dir:$Direction;Act:$Action"
        } catch {
            Write-Host "Błąd tworzenia reguły: $($_.Exception.Message)" -ForegroundColor Red
            Write-FwLog -Action "Add-Rule-Failed" -Details "$Name;Error:$($_.Exception.Message)"
        }
    }
}

function Add-FwRuleSafe {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$LocalPort,
        [string[]]$RemoteAddress = @('Any'),
        [ValidateSet('Inbound','Outbound')][string]$Direction = 'Inbound',
        [ValidateSet('Allow','Block')][string]$Action = 'Allow',
        [string]$Description = ''
    )
    Ensure-FwRule -Name $Name -LocalPort $LocalPort -RemoteAddress $RemoteAddress -Direction $Direction -Action $Action -Description $Description
}

function Remove-FwRuleSafe {
    param(
        [Parameter(Mandatory=$true)][string]$Name
    )
    $r = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    if ($r) {
        try {
            Remove-NetFirewallRule -DisplayName $Name -ErrorAction Stop
            Write-Host "Usunięto regułę: $Name" -ForegroundColor Green
            Write-FwLog -Action "Remove-Rule" -Details $Name
        } catch {
            Write-Host "Błąd usuwania reguły: $($_.Exception.Message)" -ForegroundColor Red
            Write-FwLog -Action "Remove-Rule-Failed" -Details "$Name;Error:$($_.Exception.Message)"
        }
    } else {
        Write-Host "Reguła $Name nie istnieje." -ForegroundColor Yellow
    }
}

function Block-IPSafe {
    param(
        [Parameter(Mandatory=$true)][string[]]$IPs,
        [string]$NamePrefix = "Block-IP"
    )
    foreach ($ip in $IPs) {
        $name = "$NamePrefix-$ip"
        # Normalize name (no slashes)
        $safeName = $name -replace '[\/\:\s]', '_'
        if (Test-FwRuleExists -Name $safeName -RemoteAddress @($ip) -Direction 'Inbound' -Action 'Block') {
            Write-Host "IP $ip już zablokowany (reguła: $safeName)" -ForegroundColor Yellow
            Write-FwLog -Action "Block-IP-Skipped" -Details $ip
            continue
        }
        try {
            New-NetFirewallRule -DisplayName $safeName -Direction Inbound -RemoteAddress $ip -Action Block -Enabled True -Profile Any -ErrorAction Stop
            Write-Host "Zablokowano IP: $ip" -ForegroundColor Green
            Write-FwLog -Action "Block-IP" -Details $ip
        } catch {
            Write-Host "Błąd blokowania IP $ip: $($_.Exception.Message)" -ForegroundColor Red
            Write-FwLog -Action "Block-IP-Failed" -Details "${ip};Error:$($_.Exception.Message)"
        }
    }
}

function Get-FwRulesGrouped {
    <#
    .SYNOPSIS
      Zwraca reguły pogrupowane po pierwszym tokenie z Description lub DisplayName
    #>
    param()
    $rules = Get-NetFirewallRule -ErrorAction SilentlyContinue
    $out = @()
    foreach ($r in $rules) {
        $groupKey = $null
        if ($r.Description) {
            $tk = $r.Description.Split(' ')[0]
            $groupKey = $tk
        } else {
            $groupKey = ($r.DisplayName -split ' ')[0]
        }
        $out += [PSCustomObject]@{ Group = $groupKey; Name = $r.DisplayName; Direction = $r.Direction; Action = $r.Action; Enabled = $r.Enabled }
    }
    return $out | Sort-Object Group,Name
}

function Start-FwMonitor {
    param(
        [int]$IntervalSeconds = $Global:FWMonitorIntervalSec
    )
    if (Get-Job -Name $Global:FWMonitorJobName -ErrorAction SilentlyContinue) {
        Write-Host "Monitor już działa jako Job: $Global:FWMonitorJobName" -ForegroundColor Yellow
        return
    }

    $script = {
        param($interval, $logPath)
        while ($true) {
            $now = Get-Date -Format 's'
            $conns = Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' -or $_.State -eq 'CloseWait' }
            foreach ($c in $conns) {
                $procName = $null
                try { $procName = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch {}
                $line = "$now,$($c.LocalAddress),$($c.LocalPort),$($c.RemoteAddress),$($c.RemotePort),$($c.State),$($c.OwningProcess),$procName"
                if (-not (Test-Path $logPath)) { "Time,LocalAddress,LocalPort,RemoteAddress,RemotePort,State,Pid,ProcName" | Out-File -FilePath $logPath -Encoding UTF8 }
                $line | Out-File -FilePath $logPath -Append -Encoding UTF8
            }
            Start-Sleep -Seconds $interval
        }
    }

    $job = Start-Job -Name $Global:FWMonitorJobName -ScriptBlock $script -ArgumentList $IntervalSeconds, $Global:FWLogPath
    Write-Host "Monitor uruchomiony jako job: $($job.Id) (co $IntervalSeconds s) - log: $Global:FWLogPath" -ForegroundColor Green
    Write-FwLog -Action "Start-Monitor" -Details "Interval:$IntervalSeconds"
}

function Stop-FwMonitor {
    if (Get-Job -Name $Global:FWMonitorJobName -ErrorAction SilentlyContinue) {
        Get-Job -Name $Global:FWMonitorJobName | Stop-Job -Force
        Get-Job -Name $Global:FWMonitorJobName | Remove-Job -Force
        Write-Host "Monitor zatrzymany" -ForegroundColor Green
        Write-FwLog -Action "Stop-Monitor"
    } else {
        Write-Host "Monitor nie działa" -ForegroundColor Yellow
    }
}

function Export-FwLog {
    param(
        [string]$OutFile = (Join-Path $env:USERPROFILE "firewall-log-export.csv")
    )
    if (Test-Path $Global:FWLogPath) {
        Copy-Item -Path $Global:FWLogPath -Destination $OutFile -Force
        Write-Host "Log skopiowany do: $OutFile" -ForegroundColor Green
    } else {
        Write-Host "Brak logu do eksportu" -ForegroundColor Yellow
    }
}

# Convenience: show usage
function Show-FwHelp {
    @"
FirewallManager2 - quick commands:
  Test-FwRuleExists -Name 'RuleName' -LocalPort 3000
  Ensure-FwRule -Name 'Allow-Node-3000' -LocalPort '3000' -Direction Inbound -Action Allow -Description 'Tag:DEV'
  Add-FwRuleSafe -Name 'Allow-Py-8000' -LocalPort '8000' -Action Allow
  Remove-FwRuleSafe -Name 'Allow-Py-8000'
  Block-IPSafe -IPs '1.2.3.4','192.0.2.0/24'
  Start-FwMonitor -IntervalSeconds 10
  Stop-FwMonitor
  Get-FwRulesGrouped | Format-Table -AutoSize
  Export-FwLog -OutFile C:\temp\fw-export.csv
  Get-Content $env:USERPROFILE\firewall-log.csv -Tail 50
"@ | Write-Host
}

Write-Host "FirewallManager2 loaded. Run Show-FwHelp for quick usage." -ForegroundColor Cyan
