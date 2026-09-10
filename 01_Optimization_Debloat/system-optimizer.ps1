# system-optimizer.ps1
$OutputEncoding = [System.Text.Encoding]::UTF8 # Ensure proper display of Polish characters
function Optimize-Windows {
    Write-Host "⚙️  OPTYMALIZACJA WINDOWS..." -ForegroundColor Cyan
    
    # 1. Usuń bloatware Windows
    $bloatware = @(
        "*3DBuilder*", "*Bing*", "*GetHelp*", "*GetStarted*",
        "*Messaging*", "*MicrosoftSolitaireCollection*",
        "*Office*", "*OneConnect*", "*People*", "*Print3D*",
        "*Skype*", "*Wallet*", "*WindowsAlarms*",
        "*WindowsCamera*", "*WindowsCommunicationsApps*",
        "*WindowsFeedbackHub*", "*WindowsMaps*", "*WindowsSoundRecorder*",
        "*Xbox*", "*YourPhone*", "*Zune*"
    )
    
    # 2. Optymalizacja usług
    $servicesToDisable = @(
        "DiagTrack",            # Diagnostics Tracking Service
        "dmwappushservice",     # Device Management WAP Push
        "WMPNetworkSvc",        # Windows Media Player Network Sharing
        "RemoteRegistry",       # Remote Registry
        "RemoteAccess",         # Routing and Remote Access
        "Fax",                  # Fax Service
        "lfsvc",                # Geolocation Service
        "MapsBroker",           # Downloaded Maps Manager
        "NetTcpPortSharing",    # Net.Tcp Port Sharing
        "SharedAccess",         # Internet Connection Sharing
        "TrkWks",               # Distributed Link Tracking Client
        "WbioSrvc",             # Windows Biometric Service
        "WlanSvc",              # WLAN AutoConfig
        "Wsearch"               # Windows Search
    )
    
    # 3. Optymalizacja rejestru
    $regOptimizations = @(
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="ClearPageFileAtShutdown"; Value=0; Type="DWord"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Name="EnablePrefetcher"; Value=1; Type="DWord"},
        @{Path="HKCU:\Control Panel\Desktop"; Name="MenuShowDelay"; Value="0"; Type="String"},
        @{Path="HKCU:\Control Panel\Mouse"; Name="MouseHoverTime"; Value="100"; Type="String"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="VerboseStatus"; Value=1; Type="DWord"}
    )
}
