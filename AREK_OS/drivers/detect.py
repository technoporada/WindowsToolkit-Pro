import subprocess
import json

def get_devices():
    """
    Pobiera listę urządzeń i ich InstanceId z PowerShell (Get-PnpDevice).
    """
    cmd = ["powershell", "-Command", "Get-PnpDevice | Select-Object -Property Name,InstanceId"]
    result = subprocess.run(cmd, capture_output=True, text=True)

    devices = []
    for line in result.stdout.splitlines()[3:]:  # pomijamy nagłówki
        if line.strip():
            parts = line.strip().split(None, 1)
            if len(parts) == 2:
                name, instance_id = parts
                devices.append({"device": name, "id": instance_id})
    return devices

def save_to_json(devices, path="devices.json"):
    """
    Zapisuje listę urządzeń do pliku JSON.
    """
    with open(path, "w", encoding="utf-8") as f:
        json.dump(devices, f, indent=4, ensure_ascii=False)

if __name__ == "__main__":
    devices = get_devices()
    save_to_json(devices)
    print(f"Wykryto {len(devices)} urządzeń. Zapisano do devices.json")
