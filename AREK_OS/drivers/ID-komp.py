import subprocess
import json

# 1. Wykrywanie hardware IDs przez PowerShell
def get_hardware_ids():
    cmd = ["powershell", "-Command", "Get-PnpDevice | Select-Object -Property Name,InstanceId"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    devices = []
    for line in result.stdout.splitlines()[3:]:  # pomijamy nagłówki
        if line.strip():
            parts = line.strip().split(None, 1)
            if len(parts) == 2:
                name, instance_id = parts
                devices.append({"name": name, "id": instance_id})
    return devices

# 2. Wczytanie bazy sterowników (JSON)
def load_driver_db(path="drivers.json"):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

# 3. Porównanie urządzeń z bazą
def check_drivers(devices, driver_db):
    report = []
    for dev in devices:
        matched = [d for d in driver_db if dev["id"].startswith(d["device_id"])]
        if matched:
            report.append({
                "device": dev["name"],
                "id": dev["id"],
                "status": "OK",
                "driver_version": matched[0]["driver_version"]
            })
        else:
            report.append({
                "device": dev["name"],
                "id": dev["id"],
                "status": "MISSING",
                "driver_version": None
            })
    return report

# 4. Raportowanie
def save_report(report, path="report.json"):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=4)

if __name__ == "__main__":
    devices = get_hardware_ids()
    driver_db = load_driver_db()
    report = check_drivers(devices, driver_db)
    save_report(report)
    print("Raport zapisany do report.json")
