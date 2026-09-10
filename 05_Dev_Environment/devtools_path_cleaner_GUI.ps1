Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === LOGI ===
$LogDir = "$env:USERPROFILE\devtools_path_logs"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

function Write-Log($msg) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logLine = "[$timestamp] $msg"
    Add-Content -Path $Global:LogFile -Value $logLine
    $Global:OutputBox.AppendText("$logLine`r`n")
}

# === Funkcja skanowania i naprawy PATH ===
function Run-Scan {
    $Global:LogFile = "$LogDir\log_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"

    Write-Log "=== Start skanowania ==="

    # Pobranie PATH
    $raw = $env:Path -split ';'
    $clean = @()

    foreach ($p in $raw) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $norm = $p.Trim().TrimEnd('\').ToLower()

        if (!( $clean -contains $norm )) {
            $clean += $norm
        }
    }

    Write-Log "Wyczyszczono duplikaty PATH."

    # Sprawdzenie narzędzi
    $tools = @(
        @{Name="Python"; Cmd="python"},
        @{Name="Node"; Cmd="node"},
        @{Name="Git"; Cmd="git"},
        @{Name="FFmpeg"; Cmd="ffmpeg"},
        @{Name="Choco"; Cmd="choco"}
    )

    foreach ($t in $tools) {
        $cmd = Get-Command $t.Cmd -ErrorAction SilentlyContinue
        if ($cmd) {
            $path = $cmd.Source.TrimEnd('\').ToLower()
            $folder = Split-Path $path -Parent

            if (!($clean -contains $folder)) {
                $clean += $folder
                Write-Log "Dodano brakującą ścieżkę: $folder"
            } else {
                Write-Log "$($t.Name): OK"
            }
        } else {
            Write-Log "$($t.Name): Nie znaleziono"
        }
    }

    # Zapis nowego PATH
    $newPath = ($clean -join ';')
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")

    Write-Log "PATH zapisany (User)."
    Write-Log "=== Zakończono ==="
}

# === GUI ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "DevTools PATH Cleaner"
$form.Size = New-Object System.Drawing.Size(700,600)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Skanuj i napraw"
$button.Location = New-Object System.Drawing.Point(10,10)
$button.Size = New-Object System.Drawing.Size(120,35)

$Global:OutputBox = New-Object System.Windows.Forms.TextBox
$OutputBox.Multiline = $true
$OutputBox.ScrollBars = "Vertical"
$OutputBox.Location = New-Object System.Drawing.Point(10,60)
$OutputBox.Size = New-Object System.Drawing.Size(660,490)
$OutputBox.Font = 'Consolas, 10'
$OutputBox.ReadOnly = $true

$button.Add_Click({ Run-Scan })

$form.Controls.Add($button)
$form.Controls.Add($OutputBox)

$form.ShowDialog()
