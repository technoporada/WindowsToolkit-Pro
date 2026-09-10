function Get-AudioDiagnostics {
    $result = @{
        Success = $true
        Warnings = @()
        Errors = @()
        Data = @{}
    }

    try {
        $services = @('Audiosrv', 'AudioEndpointBuilder')
        $serviceStatus = @{}
        foreach ($svc in $services) {
            try {
                $s = Get-Service -Name $svc -ErrorAction Stop
                $serviceStatus[$svc] = $s.Status.ToString()
            } catch {
                $serviceStatus[$svc] = "NotFound"
                $result.Errors += "Service $svc not found"
                $result.Success = $false
            }
        }
        $result.Data['Services'] = $serviceStatus

        try {
            $audioDevices = Get-WmiObject -Class Win32_SoundDevice -ErrorAction Stop | Select-Object Name, Status, DeviceID
            $result.Data['Devices'] = $audioDevices
        } catch {
            $result.Errors += "Failed to query Win32_SoundDevice: $($_.Exception.Message)"
            $result.Success = $false
        }

        try {
            $audioDrivers = Get-WmiObject -Class Win32_PnPSignedDriver -ErrorAction Stop | Where-Object { $_.DeviceClass -eq 'MEDIA' } | Select-Object DeviceName, DriverVersion, Manufacturer
            $result.Data['Drivers'] = $audioDrivers
        } catch {
            $result.Errors += "Failed to query audio drivers: $($_.Exception.Message)"
        }

        $programFiles = ${env:ProgramFiles}
        $programFilesX86 = ${env:ProgramFiles(x86)}
        
        $eqApoPaths = @(
            "$programFiles\EqualizerAPO",
            "$programFilesX86\EqualizerAPO"
        )
        $eqApoFound = $false
        foreach ($path in $eqApoPaths) {
            if (Test-Path $path) {
                $eqApoFound = $true
                break
            }
        }
        $result.Data['EqualizerAPO'] = $eqApoFound

        $peacePaths = @(
            "$programFiles\Peace",
            "$programFilesX86\Peace",
            "$env:LOCALAPPDATA\Programs\Peace"
        )
        $peaceFound = $false
        foreach ($path in $peacePaths) {
            if (Test-Path $path) {
                $peaceFound = $true
                break
            }
        }
        $result.Data['Peace'] = $peaceFound

        $conflicts = @('Dolby', 'Nahimic', 'Sonic Studio', 'Waves', 'FXSound', 'Realtek Audio Console', 'Sound Blaster')
        $detectedConflicts = @()
        foreach ($conflict in $conflicts) {
            $found = $false
            $checkPaths = @(
                "$programFiles\$conflict",
                "$programFilesX86\$conflict",
                "$env:LOCALAPPDATA\Programs\$conflict"
            )
            foreach ($path in $checkPaths) {
                if (Test-Path $path) {
                    $found = $true
                    break
                }
            }
            if ($found) {
                $detectedConflicts += $conflict
            }
        }
        if ($detectedConflicts.Count -gt 0) {
            $result.Warnings += "Potential audio conflicts detected: $($detectedConflicts -join ', ')"
        }
        $result.Data['Conflicts'] = $detectedConflicts

        $regKeys = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices',
            'HKLM:\SYSTEM\CurrentControlSet\Services\Audiosrv'
        )
        $regAccess = @{}
        foreach ($key in $regKeys) {
            try {
                $null = Get-Item -Path $key -ErrorAction Stop
                $regAccess[$key] = $true
            } catch {
                $regAccess[$key] = $false
                $result.Warnings += "Cannot access registry key: $key"
            }
        }
        $result.Data['RegistryAccess'] = $regAccess

    } catch {
        $result.Errors += "Audio diagnostics failed: $($_.Exception.Message)"
        $result.Success = $false
    }

    return $result
}

function Get-PythonEnvironment {
    $result = @{ Success = $false; Data = @{}; Errors = @() }
    
    # 1. Próba znalezienia przez komendę 'where'
    $pyPath = Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    
    # 2. Jeśli nie ma, szukaj w rejestrze (tam Python zawsze zostawia ślad)
    if (-not $pyPath) {
        $regPath = "HKCU:\Software\Python\PythonCore"
        if (Test-Path $regPath) {
            $version = Get-ChildItem $regPath | Select-Object -First 1 -ExpandProperty Name
            $pyPath = Get-ItemProperty "$regPath\$($version.Split('\')[-1])\InstallPath" | Select-Object -ExpandProperty "(default)"
            $pyPath = Join-Path $pyPath "python.exe"
        }
    }

    if (Test-Path $pyPath) {
        $versionInfo = & $pyPath --version 2>&1
        $result.Success = $true
        $result.Data['Version'] = $versionInfo
        $result.Data['Path'] = $pyPath
    } else {
        $result.Errors += "Python nie został znaleziony w PATH ani w rejestrze."
    }
    return $result
}

function Get-NodeEnvironment {
    $result = @{
        Success = $true
        Warnings = @()
        Errors = @()
        Data = @{}
    }

    try {
        $nodeCmd = Get-Command node.exe -ErrorAction SilentlyContinue
        if ($nodeCmd) {
            $result.Data['NodePath'] = $nodeCmd.Source
            try {
                $version = cmd /c "node -v 2>&1"
                $result.Data['NodeVersion'] = $version.Trim()
            } catch {
                $result.Warnings += "Node found but version check failed"
            }
        } else {
            $result.Data['NodePath'] = $null
            $result.Errors += "node.exe not found in PATH"
            $result.Success = $false
        }

        $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
        if ($npmCmd) {
            $result.Data['NpmPath'] = $npmCmd.Source
            try {
                $version = cmd /c "npm -v 2>&1"
                $result.Data['NpmVersion'] = $version.Trim()
            } catch {
                $result.Warnings += "npm found but version check failed"
            }
        } else {
            $result.Data['NpmPath'] = $null
            $result.Errors += "npm not found in PATH"
            $result.Success = $false
        }

        $programFiles = ${env:ProgramFiles}
        $programFilesX86 = ${env:ProgramFiles(x86)}
        
        $nodePaths = @(
            "$programFiles\nodejs",
            "$programFilesX86\nodejs"
        )
        $installations = @()
        foreach ($path in $nodePaths) {
            if (Test-Path $path) {
                $installations += $path
            }
        }
        $result.Data['Installations'] = $installations

        $npxCmd = Get-Command npx -ErrorAction SilentlyContinue
        $result.Data['NpxAvailable'] = ($null -ne $npxCmd)

        if ($npmCmd) {
            $packages = @('typescript', 'nodemon', 'http-server', 'yarn')
            $globalPackages = @{}
            foreach ($pkg in $packages) {
                try {
                    $check = cmd /c "npm list -g $pkg --depth=0 2>&1"
                    if ($check -match "$pkg@([\d\.]+)") {
                        $globalPackages[$pkg] = $matches[1]
                    } else {
                        $globalPackages[$pkg] = "NotInstalled"
                    }
                } catch {
                    $globalPackages[$pkg] = "NotInstalled"
                }
            }
            $result.Data['GlobalPackages'] = $globalPackages
        }

    } catch {
        $result.Errors += "Node environment check failed: $($_.Exception.Message)"
        $result.Success = $false
    }

    return $result
}

function Get-CommonTools {
    $result = @{
        Success = $true
        Missing = @()
        Present = @()
        Versions = @{}
    }

    $tools = @(
        @{Name='git'; VersionArg='--version'},
        @{Name='ffmpeg'; VersionArg='-version'},
        @{Name='curl'; VersionArg='--version'},
        @{Name='wget'; VersionArg='--version'},
        @{Name='7z'; VersionArg=''},
        @{Name='7za'; VersionArg=''},
        @{Name='powershell_ise.exe'; VersionArg=''},
        @{Name='winget'; VersionArg='--version'},
        @{Name='kubectl'; VersionArg='version --client'},
        @{Name='docker'; VersionArg='--version'}
    )

    foreach ($tool in $tools) {
        $cmd = Get-Command $tool.Name -ErrorAction SilentlyContinue
        if ($cmd) {
            $result.Present += $tool.Name
            if ($tool.VersionArg -ne '') {
                try {
                    $args = $tool.VersionArg -split ' '
                    $versionOutput = & $tool.Name $args 2>&1 | Select-Object -First 1
                    $result.Versions[$tool.Name] = $versionOutput.ToString().Trim()
                } catch {
                    $result.Versions[$tool.Name] = "Unknown"
                }
            } else {
                $result.Versions[$tool.Name] = "Present"
            }
        } else {
            $result.Missing += $tool.Name
        }
    }

    if ($result.Missing.Count -gt 0) {
        $result.Success = $false
    }

    return $result
}

function Get-PathSanityCheck {
    $result = @{
        Issues = @()
        DeadPaths = @()
        DuplicateEntries = @()
        Data = @{}
    }

    try {
        $pathVar = $env:PATH
        if ($pathVar) {
            $pathEntries = $pathVar -split ';' | Where-Object { $_ -ne '' }
        } else {
            $pathEntries = @()
        }
        
        $result.Data['PATH'] = $pathVar
        $result.Data['PATHEXT'] = $env:PATHEXT
        $result.Data['PYTHONPATH'] = $env:PYTHONPATH

        $seenPaths = @{}
        foreach ($entry in $pathEntries) {
            $normalized = $entry.ToLower().TrimEnd('\')
            if ($seenPaths.ContainsKey($normalized)) {
                $result.DuplicateEntries += $entry
                $result.Issues += "Duplicate PATH entry: $entry"
            } else {
                $seenPaths[$normalized] = $true
            }

            if (-not (Test-Path $entry -ErrorAction SilentlyContinue)) {
                $result.DeadPaths += $entry
                $result.Issues += "Dead PATH entry (does not exist): $entry"
            }
        }

        $nodePaths = $pathEntries | Where-Object { $_ -match 'nodejs' }
        if ($nodePaths.Count -gt 1) {
            $result.Issues += "Multiple Node.js entries detected in PATH: $($nodePaths -join '; ')"
        }

        $pythonPaths = $pathEntries | Where-Object { $_ -match 'python' }
        if ($pythonPaths.Count -gt 1) {
            $result.Issues += "Multiple Python entries detected in PATH: $($pythonPaths -join '; ')"
        }

    } catch {
        $result.Issues += "PATH sanity check failed: $($_.Exception.Message)"
    }

    return $result
}

function Test-SystemEnvironment {
    $report = [PSCustomObject]@{
        Audio     = Get-AudioDiagnostics
        Python    = Get-PythonEnvironment
        Node      = Get-NodeEnvironment
        Tools     = Get-CommonTools
        PathCheck = Get-PathSanityCheck
    }

    return $report
}

Test-SystemEnvironment
