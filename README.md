# 🛠️ WindowsToolkit-Pro

**Kolekcja skryptów PowerShell do optymalizacji, bezpieczeństwa i setupu Windows**

Stworzone przez **StruśPędziKOD** / [technoporada](https://github.com/technoporada)

## 📁 Struktura

```
WindowsToolkit-Pro/
├── 01_Optimization_Debloat/     # Optymalizacja i czyszczenie Windows
├── 02_Security_Firewall/        # Bezpieczeństwo i firewall
├── 04_System_Health/            # Diagnostyka i zdrowie systemu
├── 05_Dev_Environment/          # Setup środowiska developera
├── 05_System_Repair/            # Naprawa systemu
├── _SKRYPTY_INSTALACYJNE/       # Instalatory narzędzi
├── AREK_OS/                     # Detekcja driverów, cross-platform
├── windowsPS1/                  # Narzędzia Windows
├── src_diagnoza/                # Diagnostyka (Claude)
├── src_tools/                   # Zaawansowane narzędzia
└── validate_all_ps1.ps1         # Walidator składni PS1
```

## 🚀 Szybki Start

```powershell
# 1. Setup dev environment
.\05_Dev_Environment\dev-setup.ps1

# 2. Security audit
.\02_Security_Firewall\diagnozaCLAUDE.ps1

# 3. System health check
.\04_System_Health\windows_health_check_final_AREK.ps1
```

## 📋 Kategorie

### 🧹 Optimization (01)
- `system-optimizer.ps1` - Ogólna optymalizacja
- `cleanup-powershell5-1ver2.ps1` - Czyszczenie PS5
- `winopt-launcher.ps1` - Launcher z GUI (HTML)

### 🛡️ Security (02)
- `FirewallManager2.ps1` - Zarządzanie firewallem
- `win10_debloat_security.ps1` - Debloat + security hardening
- `diagnozaCLAUDE.ps1` - Diagnostyka bezpieczeństwa

### 💻 Dev Environment (05)
- `dev-setup.ps1` - Setup katalogów dev
- `Setup-DevEnvironment.ps1` - Pełny setup (Python, Node, Git)
- `env-setupENG.ps1` - Environment setup (EN)
- `env-setupPL.ps1` - Environment setup (PL)
- `clean_node.ps1` - Czyszczenie cache npm
- `WSL-dev-setup.sh` - Setup WSL (bash)

### 🔧 System Health (04)
- `windows_health_check_final_AREK.ps1` - Health check
- `directx-repair.ps1` - Naprawa DirectX
- `WinInspect.ps1` - Inspekcja systemu
- `yt-dlp-updater.ps1` - Aktualizator yt-dlp

### 📦 Installers (_SKRYPTY_INSTALACYJNE)
- `AIO.ps1` - All-In-One (Gamer/Dev/Admin modes)
- `setup-dev-user.ps1` - Tworzenie konta dev
- `install-pyenv-win.ps1` - Instalator pyenv
- `Brutalny-killer.ps1` - Zabijanie procesów

## ⚠️ Bezpieczeństwo

- **Hasła** - Używaj `Read-Host -AsSecureString` zamiast hardkodować
- **ExecutionPolicy** - Skrypty używają `Bypass` dla processu (bezpieczne)
- **Pobieranie** - Tylko z zaufanych źródeł (Chocolatey, GitHub, PyEnv)
- **Backup** - Zawsze rób punkt przywracania przed uruchomieniem

## 🔧 Wymagania

- Windows 10/11
- PowerShell 5.1+
- Opcjonalnie: winget, chocolatey

## 📜 Licencja

MIT - Używaj jak chcesz

## 👤 Autor

**StruśPędziKOD** / [technoporada](https://github.com/technoporada)

---

*"Bo nawet Windows czasem potrzebuje pomocy"* 🦩
