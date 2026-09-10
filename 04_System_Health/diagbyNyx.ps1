function Get-InstalledPrograms {
    Step "Diagnostyka" "Programy - pobieranie"
    try {
        $programs = @()
        $registryPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        foreach ($path in $registryPaths) {
            try {
                Get-ItemProperty -Path $path -ErrorAction Stop | ForEach-Object {
                    if ($_.DisplayName) {
                        $programs += @{
                            Name = $_.DisplayName
                            Publisher = $_.Publisher
                            Version = $_.DisplayVersion
                            InstallDate = $_.InstallDate
                        }
                    }
                }
            } catch {
                Write-Log ("Błąd przetwarzania rejestru {0}: {1}" -f $path, $_) -Level "WARNING"
            }
        }

        # Bezpieczne sprawdzenie Program Files i Program Files (x86)
        $pfPaths = @(
            $env:ProgramFiles,
            ${env:ProgramFiles(x86)}
        )
        foreach ($pf in $pfPaths) {
            if ($pf -and (Test-Path $pf)) {
                try {
                    Get-ChildItem -Path $pf -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                        $programs += @{ Name = $_.Name; Publisher = ""; Version = ""; InstallDate = "" }
                    }
                } catch {
                    Write-Log ("Błąd skanowania {0}: {1}" -f $pf, $_) -Level "WARNING"
                }
            } else {
                Write-Log ("Katalog nie istnieje lub brak dostępu: {0}" -f $pf) -Level "INFO"
            }
        }

        $script:ReportData.InstalledPrograms = $programs
        Write-Log "InstalledPrograms OK"
    } catch {
        Write-Log ("Błąd Get-InstalledPrograms: {0}" -f $_) -Level "ERROR"
        $script:ReportData.InstalledPrograms = @(@{ Error = "Nie udało się pobrać listy programów" })
    }
}
