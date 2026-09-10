import subprocess
import json

def load_report(path="match_report.json"):
    """
    Wczytuje raport dopasowania sterowników (z match.py)
    """
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def install_driver(inf_path):
    """
    Instaluje sterownik przez pnputil
    """
    cmd = ["pnputil", "/add-driver", inf_path, "/install"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout, result.stderr

def process_report(report):
    """
    Przechodzi przez raport i próbuje zainstalować brakujące sterowniki
    """
    for entry in report:
        if entry["status"] == "FOUND":
            # zakładamy, że mamy ścieżkę do INF w bazie sterowników
            inf_path = f"drivers/{entry['vendor']}/{entry['device']}.inf"
            print(f"Instaluję sterownik dla {entry['device']} ({entry['id']})...")
            stdout, stderr = install_driver(inf_path)
            print("Wynik:", stdout)
            if stderr:
                print("Błąd:", stderr)

if __name__ == "__main__":
    report = load_report()
    process_report(report)
