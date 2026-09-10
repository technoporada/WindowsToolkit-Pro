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

        $eqApoPaths = @(
            "${env:ProgramFiles}\EqualizerAPO",
            "${env:ProgramFiles(x86)}\EqualizerAPO"
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
            "${env:ProgramFiles}\Peace",
            "${env:ProgramFiles(x86)}\Peace",
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
                "${env:ProgramFiles}\$conflict",
                "${env:ProgramFiles(x86)}\$conflict",
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
    $result = @{
        Success = $true
        Warnings = @()
        Errors = @()
        Data = @{}
    }

    try {
        $pythonCmd = Get-Command python.exe -ErrorAction SilentlyContinue
        if ($pythonCmd) {
            $result.Data['PythonPath'] = $pythonCmd.Source
            try {
                $version = & python --version 2>&1
                $result.Data['Version'] = $version.ToString()
            } catch {
                $result.Warnings += "Python found but version check failed"
            }
        } else {
            $result.Data['PythonPath'] = $null
            $result.Errors += "python.exe not found in PATH"
            $result.Success = $false
        }

        $regPaths = @(
            'HKLM:\SOFTWARE\Python',
            'HKLM:\SOFTWARE\WOW6432Node\Python'
        )
        $regPython = @()
        foreach ($path in $regPaths) {
            if (Test-Path $path) {
                try {
                    $keys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                    foreach ($key in $keys) {
                        $regPython += $key.PSPath
                    }
                } catch {}
            }
        }
        $result.Data['RegistryEntries'] = $regPython

        $venvCmd = Get-Command venv -ErrorAction SilentlyContinue
        $result.Data['VenvAvailable'] = ($null -ne $venvCmd)

        $pipCmd = Get-Command pip -ErrorAction SilentlyContinue
        if ($pipCmd) {
            $result.Data['PipPath'] = $pipCmd.Source
        } else {
            $result.Data['PipPath'] = $null
            $result.Warnings += "pip not found in PATH"
        }

        if ($pythonCmd) {
            try {
                $sitePackages = & python -c "import site; print(site.getsitepackages()[0])" 2>&1
                $result.Data['SitePackages'] = $sitePackages.ToString().Trim()
            } catch {
                $result.Data['SitePackages'] = $null
            }

            $libraries = @('requests', 'psutil', 'fastapi')
            $installedLibs = @{}
            foreach ($lib in $libraries) {
                try {
                    $check = & python -c "import $lib; print($lib.__version__)" 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $installedLibs[$lib] = $check.ToString().Trim()
                    } else {
                        $installedLibs[$lib] = "NotInstalled"
                    }
                } catch {
                    $installedLibs[$lib] = "NotInstalled"
                }
            }
            $result.Data['Libraries'] = $installedLibs
        }

    } catch {
        $result.Errors += "Python environment check failed: $($_.Exception.Message)"
        $result.Success = $false
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
                $version = & node -v 2>&1
                $result.Data['NodeVersion'] = $version.ToString().Trim()
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
                $version = & npm -v 2>&1
                $result.Data['NpmVersion'] = $version.ToString().Trim()
            } catch {
                $result.Warnings += "npm found but version check failed"
            }
        } else {
            $result.Data['NpmPath'] = $null
            $result.Errors += "npm not found in PATH"
            $result.Success = $false
        }

        $nodePaths = @(
            "${env:ProgramFiles}\nodejs",
            "${env:ProgramFiles(x86)}\nodejs"
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
                    $check = & npm list -g $pkg --depth=0 2>&1
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
                    $versionOutput = & $tool.Name $tool.VersionArg.Split(' ') 2>&1
                    $result.Versions[$tool.Name] = $versionOutput[0].ToString().Trim()
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
    }

    try {
        $pathVar = $env:PATH
        $pathEntries = $pathVar -split ';' | Where-Object { $_ -ne '' }
        
        $result.Data = @{
            PATH = $pathVar
            PATHEXT = $env:PATHEXT
            PYTHONPATH = $env:PYTHONPATH
        }

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
