import subprocess
import json

def get_driver_info():
    """
    Pobiera listę sterowników zainstalowanych w systemie (pnputil /enum-drivers).
    """
    cmd = ["pnputil", "/enum-drivers"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout

def parse_driver_info(raw_output):
    """
    Parsuje output pnputil i zwraca listę sterowników z Device Name + Version.
    """
    drivers = []
    current = {}
    for line in raw_output.splitlines():
        line = line.strip()
        if line.startswith("Published Name"):
            current["published_name"] = line.split(":")[1].strip()
        elif line.startswith("Driver Package Provider"):
            current["provider"] = line.split(":")[1].strip()
        elif line.startswith("Driver Version"):
            current["version"] = line.split(":")[1].strip()
        elif line == "":
            if current:
                drivers.append(current)
                current = {}
    return drivers

def load_report(path="match_report.json"):
    """
    Wczytuje raport dopasowania (z match.py).
    """
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def sanity_check(report, drivers):
    """
    Sprawdza, czy sterowniki z raportu faktycznie są w systemie.
    """
    final_report = []
    for entry in report:
        status = entry["status"]
        found = False
        for d in drivers:
            if entry["vendor"] and entry["vendor"].lower() in d.get("provider","").lower():
                found = True
                break
        if found:
            final_report.append({
                "device": entry["device"],
                "id": entry["id"],
                "status": "OEM_OK",
                "driver_version": entry["driver_version"]
            })
        else:
            final_report.append({
                "device": entry["device"],
                "id": entry["id"],
                "status": "GENERIC_OR_MISSING",
                "driver_version": None
            })
    return final_report

def save_final_report(report, path="sanity_report.json"):
    """
    Zapisuje końcowy raport sanity-check.
    """
    with open(path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=4, ensure_ascii=False)

if __name__ == "__main__":
    raw_output = get_driver_info()
    drivers = parse_driver_info(raw_output)
    report = load_report()
    final_report = sanity_check(report, drivers)
    save_final_report(final_report)
    print("Sanity-check zakończony. Raport zapisany do sanity_report.json")
