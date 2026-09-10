# setup.ps1 - MusicTools Auto-Setup (v2)
# Autor: Arek + NyX (AI Support)
# Cel: Pełna instalacja narzędzi muzycznych + prosty lokalny GUI

$ToolsDir = "C:\Tools\MusicTools"
$BinDir = "$ToolsDir\bin"
$ConfigDir = "$ToolsDir\configs"
$LogsDir = "$ToolsDir\logs"
$GuiDir = "$ToolsDir\gui"
$MusicDir = "$ToolsDir\Music"

# --- Katalogi ---
@($BinDir, $ConfigDir, $LogsDir, $GuiDir, $MusicDir) | ForEach-Object {
    if (!(Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# --- Narzędzia do pobrania ---
$tools = @(
    @{Name="yt-dlp.exe"; Url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"},
    @{Name="ffmpeg.zip"; Url="https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"},
    @{Name="aria2.zip"; Url="https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip"},
    @{Name="mpv.7z"; Url="https://sourceforge.net/projects/mpv-player-windows/files/64bit/mpv-0.35.0-x86_64.7z"}
)

Write-Host "`n=== 🔧 Installing dependencies... ===`n"

foreach ($tool in $tools) {
    $destPath = Join-Path $BinDir $tool.Name
    $fileName = [IO.Path]::GetFileName($destPath)
    $downloadPath = Join-Path $BinDir $fileName

    if ( (Test-Path $downloadPath) -or (Test-Path ($downloadPath -replace '\.zip|\.7z', '.exe')) ) {
        Write-Host "$fileName already present, skipping."
        continue
    }

    Write-Host "Downloading $fileName..."
    Invoke-WebRequest -Uri $tool.Url -OutFile $downloadPath

    if ($downloadPath -match "\.zip$") {
        Expand-Archive -Path $downloadPath -DestinationPath $BinDir -Force
        Remove-Item $downloadPath
    } elseif ($downloadPath -match "\.7z$") {
        if (Test-Path "C:\Program Files\7-Zip\7z.exe") {
            & "C:\Program Files\7-Zip\7z.exe" x $downloadPath "-o$BinDir" -y
            Remove-Item $downloadPath
        } else {
            Write-Host "⚠ 7-Zip not found. Please install it to extract $fileName."
        }
    }
}

# --- Konfiguracja ---
@"
--no-mtime
-o $MusicDir\%(title)s.%(ext)s
--format bestaudio/best
--extract-audio
--audio-format mp3
--audio-quality 0
"@ | Out-File "$ConfigDir\yt-dlp.conf" -Encoding utf8

@"
dir=$MusicDir
log-level=warn
enable-rpc=true
rpc-listen-all=true
"@ | Out-File "$ConfigDir\aria2.conf" -Encoding utf8

# --- GUI ---
@"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>MusicTools</title>
  <style>
    body { font-family: Arial; background: #202020; color: #fff; margin: 40px; }
    input, button { padding: 10px; margin: 5px; font-size: 16px; }
    input { width: 300px; }
    button { background-color: #0a84ff; border: none; color: white; border-radius: 6px; }
    h1 { color: #00d1b2; }
  </style>
</head>
<body>
  <h1>🎵 MusicTools</h1>
  <input type="text" id="url" placeholder="Enter YouTube/Spotify URL">
  <button onclick="download()">Download</button>
  <pre id="status"></pre>

  <script>
    async function download() {
      const url = document.getElementById('url').value;
      const res = await fetch('/download', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({url})
      });
      const data = await res.text();
      document.getElementById('status').innerText = data;
    }
  </script>
</body>
</html>
"@ | Out-File "$GuiDir\index.html" -Encoding utf8

# --- Backend PowerShell (Start-Server.ps1) ---
@"
param([int]`$Port = 8080)

Add-Type -AssemblyName System.Web
`$listener = New-Object System.Net.HttpListener
`$listener.Prefixes.Add("http://localhost:`$Port/")
`$listener.Start()
Write-Host "🌐 MusicTools GUI available at: http://localhost:`$Port"

while (`$listener.IsListening) {
    `$context = `$listener.GetContext()
    `$req = `$context.Request
    `$resp = `$context.Response

    if (`$req.HttpMethod -eq "GET" -and `$req.Url.AbsolutePath -eq "/") {
        `$html = Get-Content "$GuiDir\index.html" -Raw
        `$bytes = [Text.Encoding]::UTF8.GetBytes(`$html)
        `$resp.OutputStream.Write(`$bytes,0,`$bytes.Length)
    }
    elseif (`$req.HttpMethod -eq "POST" -and `$req.Url.AbsolutePath -eq "/download") {
        `$body = (New-Object IO.StreamReader `$req.InputStream).ReadToEnd()
        `$json = ConvertFrom-Json `$body
        `$url = `$json.url

        Start-Process "$BinDir\yt-dlp.exe" "-a `$url --config-location `$ConfigDir\yt-dlp.conf" -NoNewWindow
        `$msg = "Downloading: `$url"
        `$bytes = [Text.Encoding]::UTF8.GetBytes(`$msg)
        `$resp.OutputStream.Write(`$bytes,0,`$bytes.Length)
    }

    `$resp.Close()
}
"@ | Out-File "$GuiDir\Start-Server.ps1" -Encoding utf8

# --- Skrót startowy ---
@"
@echo off
powershell -ExecutionPolicy Bypass -File "$GuiDir\Start-Server.ps1"
"@ | Out-File "$ToolsDir\start_gui.bat" -Encoding ascii

Write-Host "`n✅ Setup completed!"
Write-Host "➡ Run 'start_gui.bat' to launch the interface at http://localhost:8080"
