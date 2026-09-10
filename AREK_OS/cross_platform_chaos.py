#!/usr/bin/env python3
import os
import sys
import platform
import subprocess
import json
import time
import threading
from datetime import datetime
from pathlib import Path

class CrossPlatformChaos:
    def __init__(self):
        # Konfiguracja dla Windows 10
        self.platform = platform.system()
        self.is_windows = self.platform == "Windows"
        
        # Ścieżki specyficzne dla Windows
        if self.is_windows:
            self.user_home = Path(os.path.expanduser("~"))
            self.chaos_dir = self.user_home / "chaos_workspace"
            self.temp_dir = self.user_home / "temp_chaos"
            self.backup_dir = self.user_home / "chaos_backup"
        else:
            self.chaos_dir = Path("/home/h5n1/chaos_workspace")
            self.temp_dir = Path("/tmp/chaos_temp")
            self.backup_dir = Path("/home/h5n1/chaos_backup")
        
        # Konfiguracja dla Windows
        self.windows_config = {
            'python_executable': 'python',
            'shell': True,
            'encoding': 'utf-8',
            'newline': '\r\n',
            'path_separator': '\\',
            'line_ending': '\r\n'
        }
        
        # Inicjalizacja
        self.initialize_system()
    
    def initialize_system(self):
        """Inicjalizuje system chaosu na Windows 10"""
        print("🪟 CROSS PLATFORM CHAOS")
        print("=" * 50)
        print(f"🖥️ Platforma: {self.platform}")
        print(f"📁 Katalog chaosu: {self.chaos_dir}")
        print(f"📁 Katalog tymczasowy: {self.temp_dir}")
        print(f"📁 Katalog backup: {self.backup_dir}")
        print("=" * 50)
        
        # Utwórz katalogi
        self.create_directories()
        
        # Konfiguracja dla Windows
        if self.is_windows:
            self.configure_windows()
        
        # Sprawdź środowisko
        self.check_environment()
        
        print("✅ System zainicjalizowany")
    
    def create_directories(self):
        """Tworzy niezbędne katalogi"""
        directories = [self.chaos_dir, self.temp_dir, self.backup_dir]
        
        for directory in directories:
            try:
                directory.mkdir(parents=True, exist_ok=True)
                print(f"📁 Utworzono katalog: {directory}")
            except Exception as e:
                print(f"⚠️  Błąd tworzenia katalogu {directory}: {e}")
    
    def configure_windows(self):
        """Konfiguruje środowisko Windows"""
        print("🔧 Konfiguracja dla Windows 10...")
        
        # Sprawdź Python
        try:
            python_version = sys.version_info
            print(f"🐍 Python: {python_version.major}.{python_version.minor}.{python_version.micro}")
            
            if python_version < (3, 7):
                print("⚠️  Zalecane Python 3.7+ dla pełnej funkcjonalności")
        except:
            print("⚠️  Nie można sprawdzić wersji Python")
        
        # Sprawdź moduły
        required_modules = ['tkinter', 'pathlib', 'threading', 'json', 'hashlib']
        missing_modules = []
        
        for module in required_modules:
            try:
                __import__(module)
            except ImportError:
                missing_modules.append(module)
        
        if missing_modules:
            print("⚠️  Brakujące moduły:")
            for module in missing_modules:
                print(f"   • {module}")
            print("\n💡 Instalacja brakujących modułów:")
            print("   pip install " + " ".join(missing_modules))
        
        # Konfiguracja PowerShell
        try:
            result = subprocess.run(
                ['powershell', '-Command', 'Get-ExecutionPolicy'],
                capture_output=True,
                text=True,
                shell=True
            )
            if 'Restricted' in result.stdout:
                print("⚠️  PowerShell jest w trybie Restricted")
                print("💡 Uruchom jako Administrator:")
                print("   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser")
        except:
            print("⚠️  Nie można sprawdzić polityki wykonania PowerShell")
    
    def check_environment(self):
        """Sprawdza środowisko"""
        print("🔍 Sprawdzanie środowiska...")
        
        # Sprawdź uprawnienia
        if self.is_windows:
            try:
                # Spróbuj utworzyć plik testowy
                test_file = self.temp_dir / "test_write.txt"
                with open(test_file, 'w') as f:
                    f.write("Test zapisu na Windows")
                
                # Spróbuj odczytać
                with open(test_file, 'r') as f:
                    content = f.read()
                
                print(f"✅ Test zapisu/odczytu: SUKCES")
                print(f"   📄 Zawartość: {content[:30]}...")
                
                # Usuń plik testowy
                test_file.unlink()
                
            except Exception as e:
                print(f"⚠️  Błąd testu zapisu/odczytu: {e}")
        
        # Sprawdź dostęp do katalogów
        for directory in [self.chaos_dir, self.temp_dir, self.backup_dir]:
            if directory.exists():
                print(f"✅ Dostęp do katalogu: {directory}")
            else:
                print(f"⚠️  Brak dostępu do katalogu: {directory}")
    
    def run_windows_command(self, command, cwd=None, shell=True):
        """Uruchamia komendę na Windows"""
        try:
            if cwd:
                result = subprocess.run(
                    command,
                    cwd=cwd,
                    shell=shell,
                    capture_output=True,
                    text=True,
                    encoding='utf-8'
                )
            else:
                result = subprocess.run(
                    command,
                    shell=shell,
                    capture_output=True,
                    text=True,
                    encoding='utf-8'
                )
            
            return result
        except Exception as e:
            print(f"⚠️  Błąd wykonania komendy: {e}")
            return None
    
    def create_chaos_project(self, project_name):
        """Tworzy nowy projekt chaosu na Windows"""
        print(f"🚀 Tworzenie projektu chaosu: {project_name}")
        
        project_dir = self.chaos_dir / project_name
        project_dir.mkdir(parents=True, exist_ok=True)
        
        # Struktura projektu
        dirs_to_create = [
            'src',
            'tests',
            'docs',
            'config',
            'backup'
        ]
        
        for dir_name in dirs_to_create:
            (project_dir / dir_name).mkdir(parents=True, exist_ok=True)
        
        # Pliki projektu
        files_to_create = [
            ('src', 'main.py', f"# {project_name} - Główny plik\n# Utworzony: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"),
            ('config', 'settings.json', '{"project": "' + project_name + '", "platform": "Windows 10"}'),
            ('docs', 'README.md', f"# {project_name}\n\n## Opis\nProjekt chaosu działający na Windows 10.\n\n## Struktura\n- src/: Kod źródłowy\n- tests/: Testy jednostkowe\n- docs/: Dokumentacja\n- config/: Konfiguracja\n"),
            ('tests', 'test_main.py', f"import sys\nsys.path.append(str(Path(__file__).parent.parent))\nfrom src.main import main\n\nif __name__ == '__main__':\n    main()")
        ]
        
        for dir_name, filename, content in files_to_create:
            file_path = project_dir / dir_name / filename
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        
        print(f"✅ Projekt {project_name} utworzony w: {project_dir}")
        
        # Uruchomienie w PowerShell
        ps_command = f'Set-Location -Path "{project_dir}"'
        self.run_windows_command(ps_command)
        
        return project_dir
    
    def run_chaos_test(self, project_dir):
        """Uruchamia test chaosu na Windows"""
        print(f"🧪 Uruchamianie testu chaosu: {project_dir}")
        
        # Uruchom testy
        test_command = f'python "{project_dir}/tests/test_main.py"'
        result = self.run_windows_command(test_command, cwd=project_dir)
        
        if result:
            print("📊 Wynik testu:")
            print(result.stdout)
            if result.returncode == 0:
                print("✅ Test zakończony sukcesem")
            else:
                print("⚠️  Test zakończony z błędami")
        else:
            print("⚠️  Nie można uruchomić testu")
    
    def create_chaos_gui(self, project_dir):
        """Tworzy GUI dla projektu chaosu na Windows"""
        print(f"🖥️ Tworzenie GUI dla projektu: {project_dir}")
        
        gui_file = project_dir / 'src' / 'gui.py'
        
        gui_code = f'''
import tkinter as tk
from tkinter import ttk
import threading
import time

class ChaosGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("{project_name} - Chaos GUI")
        self.root.geometry("800x600")
        
        # Tytuł
        title_label = tk.Label(
            self.root,
            text="🌀 {project_name} - Chaos GUI",
            font=('Arial', 16, 'bold'),
            fg='#ff00de',
            bg='black'
        )
        title_label.pack(pady=20)
        
        # Panel sterowania
        control_frame = ttk.LabelFrame(self.root, text="Panel Sterowania", padding=10)
        control_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Przyciski
        ttk.Button(
            control_frame,
            text="Uruchom Chaos",
            command=self.run_chaos
        ).pack(side='left', padx=5)
        
        ttk.Button(
            control_frame,
            text="Testuj System",
            command=self.test_system
        ).pack(side='left', padx=5)
        
        ttk.Button(
            control_frame,
            text="Pokaż Status",
            command=self.show_status
        ).pack(side='left', padx=5)
        
        # Status
        self.status_label = tk.Label(
            self.root,
            text="Status: Gotowy do chaosu",
            font=('Arial', 10),
            fg='#00ff88',
            bg='black'
        )
        self.status_label.pack(pady=10)
        
        # Log
        self.log_text = tk.Text(
            self.root,
            height=10,
            width=80,
            bg='black',
            fg='#00ff88',
            font=('Courier New', 9)
        )
        self.log_text.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.root.mainloop()
    
    def run_chaos(self):
        self.log_text.insert(tk.END, "🚀 Uruchamianie chaosu...")
        self.status_label.config(text="Status: Chaos w toku...")
        self.root.update()
        
        # Symulacja pracy w tle
        def chaos_worker():
            for i in range(5):
                time.sleep(1)
                self.log_text.insert(tk.END, f"🌀 Krok chaosu {{i+1}}/5")
                self.log_text.see(tk.END)
                self.root.update()
            
            self.log_text.insert(tk.END, "✅ Chaos zakończony!")
            self.status_label.config(text="Status: Chaos zakończony")
            self.root.update()
        
        thread = threading.Thread(target=chaos_worker)
        thread.daemon = True
        thread.start()
    
    def test_system(self):
        self.log_text.insert(tk.END, "🧪 Testowanie systemu...")
        self.status_label.config(text="Status: Testowanie...")
        self.root.update()
        
        # Symulacja testu
        test_results = [
            "✅ Moduł główny: OK",
            "✅ Testy jednostkowe: OK",
            "✅ Konfiguracja: OK",
            "⚠️  Wydajność: Wymaga optymalizacji"
        ]
        
        for result in test_results:
            time.sleep(0.5)
            self.log_text.insert(tk.END, result)
            self.log_text.see(tk.END)
            self.root.update()
        
        self.status_label.config(text="Status: Test zakończony")
        self.root.update()
    
    def show_status(self):
        self.log_text.insert(tk.END, "📊 STATUS SYSTEMU")
        self.log_text.insert(tk.END, f"Platforma: {platform.system()}")
        self.log_text.insert(tk.END, f"Python: {{sys.version}}")
        self.log_text.insert(tk.END, f"Katalog: {{os.getcwd()}}")
        self.log_text.see(tk.END)
        self.root.update()

if __name__ == '__main__':
    app = ChaosGUI()
    app.run()
'''
        
        with open(gui_file, 'w', encoding='utf-8') as f:
            f.write(gui_code)
        
        print(f"✅ GUI utworzony: {gui_file}")
        
        # Uruchom GUI
        gui_command = f'python "{gui_file}"'
        self.run_windows_command(gui_command)
    
    def show_windows_info(self):
        """Pokazuje informacje o Windows 10"""
        print("🖥️ INFORMACJE O WINDOWS 10")
        print("=" * 50)
        
        # Informacje systemowe
        system_info = {
            'platform': platform.system(),
            'platform_release': platform.release(),
            'platform_version': platform.version(),
            'machine': platform.machine(),
            'processor': platform.processor(),
            'architecture': platform.architecture()
        }
        
        for key, value in system_info.items():
            print(f"📊 {{key}}: {{value}}")
        
        # Informacje o Python
        python_info = {
            'version': sys.version,
            'executable': sys.executable,
            'path': sys.path
        }
        
        print("\n🐍 INFORMACJE O PYTHON:")
        for key, value in python_info.items():
            print(f"📊 {{key}}: {{value}}")
        
        # Informacje o katalogach
        print(f"\n📁 KATALOGI CHAOSU:")
        print(f"   🏠 Główny: {{self.chaos_dir}}")
        print(f"   📁 Tymczasowy: {{self.temp_dir}}")
        print(f"   📁 Backup: {{self.backup_dir}}")

def main():
    """Główna funkcja"""
    parser = argparse.ArgumentParser(description="Cross Platform Chaos - System chaosu na Windows 10")
    parser.add_argument('--create', help='Tworzy nowy projekt chaosu')
    parser.add_argument('--test', help='Testuje projekt chaosu')
    parser.add_argument('--gui', help='Uruchamia GUI dla projektu')
    parser.add_argument('--info', action='store_true', help='Pokazuje informacje o systemie')
    parser.add_argument('--project', help='Nazwa projektu do utworzenia/testu')
    
    args = parser.parse_args()
    
    chaos = CrossPlatformChaos()
    
    if args.info:
        chaos.show_windows_info()
    elif args.create:
        project_name = args.project if args.project else f"windows_chaos_{{datetime.now().strftime('%Y%m%d_%H%M%S')}}"
        project_dir = chaos.create_chaos_project(project_name)
        print(f"\n🚀 Projekt utworzony! Uruchom:")
        print(f"   python {{project_dir}}/src/gui.py  # GUI")
        print(f"   python {{project_dir}}/tests/test_main.py  # Testy")
    elif args.test:
        if args.project:
            project_dir = chaos.chaos_dir / args.project
            if project_dir.exists():
                chaos.run_chaos_test(project_dir)
            else:
                print(f"⚠️  Projekt {args.project} nie istnieje")
        else:
            print("⚠️  Podaj nazwę projektu --project <nazwa>")
    elif args.gui:
        if args.project:
            project_dir = chaos.chaos_dir / args.project
            if project_dir.exists():
                chaos.create_chaos_gui(project_dir)
            else:
                print(f"⚠️  Projekt {args.project} nie istnieje")
        else:
            print("⚠️  Podaj nazwę projektu --project <nazwa>")
    else:
        print("🪟 CROSS PLATFORM CHAOS")
        print("Dostępne opcje:")
        print("  --create    : Tworzy nowy projekt")
        print("  --test      : Testuje projekt")
        print("  --gui       : Uruchamia GUI")
        print("  --info      : Pokazuje informacje o systemie")
        print("\n💡 Przykład użycia:")
        print("  python cross_platform_chaos.py --create --project mój_chaos")
        print("  python cross_platform_chaos.py --test --project mój_chaos")
        print("  python cross_platform_chaos.py --gui --project mój_chaos")

if __name__ == '__main__':
    main()
