# yt-dlp-updater.ps1
$OutputEncoding = [System.Text.Encoding]::UTF8 # Ensure proper display of Polish characters
param([string]$ToolsDir = "C:\Tools\MusicTools")

$ytDlpPaths = @(
    "$ToolsDir\bin\yt-dlp.exe",                    # Nasza lokalna kopia
    "$env:LOCALAPPDATA\Programs\yt-dlp\yt-dlp.exe", # Winget install
    "$env:ProgramFiles\yt-dlp\yt-dlp.exe"           # Manual install
)

$updateSources = @(
    @{Name="GitHub"; Url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"},
    @{Name="SourceForge"; Url="https://sourceforge.net/projects/yt-dlp/files/latest/download"},
    @{Name="yt-dlp.org"; Url="https://yt-dlp.org/downloads/latest/yt-dlp.exe"}
)

function Test-Url($url) {
    try {
        $req = [System.Net.WebRequest]::Create($url)
        $req.Method = "HEAD"
        $req.Timeout = 5000
        $resp = $req.GetResponse()
        $resp.Close()
        return $true
    } catch { return $false }
}

function Update-YtDlp($targetPath) {
    Write-Host "🔄 Aktualizacja yt-dlp..." -ForegroundColor Yellow
    
    # Próbuj z każdego źródła
    foreach ($source in $updateSources) {
        Write-Host "   Próbuję: $($source.Name)..." -NoNewline
        
        if (Test-Url $source.Url) {
            try {
                Invoke-WebRequest -Uri $source.Url -OutFile $targetPath -TimeoutSec 30
                Write-Host " ✅" -ForegroundColor Green
                
                # Sprawdź wersję
                $version = & $targetPath --version 2>$null
                Write-Host "   Wersja: $version" -ForegroundColor Cyan
                return $true
            } catch {
                Write-Host " ❌ ($_)" -ForegroundColor Red
            }
        } else {
            Write-Host " ❌ (URL nie działa)" -ForegroundColor Red
        }
    }
    
    return $false
}

# Znajdź aktualny yt-dlp
$currentYtDlp = $null
foreach ($path in $ytDlpPaths) {
    if (Test-Path $path) {
        $currentYtDlp = $path
        break
    }
}

if (-not $currentYtDlp) {
    $currentYtDlp = "$ToolsDir\bin\yt-dlp.exe"
    New-Item -ItemType Directory -Path "$ToolsDir\bin" -Force | Out-Null
}

if (Update-YtDlp $currentYtDlp) {
    Write-Host "✅ yt-dlp zaktualizowany!" -ForegroundColor Green
} else {
    Write-Host "❌ Nie udało się zaktualizować yt-dlp" -ForegroundColor Red
}
