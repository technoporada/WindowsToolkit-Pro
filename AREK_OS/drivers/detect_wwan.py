import json
import subprocess

def get_net_adapters():
    cmd = [
        "powershell",
        "-Command",
        "Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress | ConvertTo-Json"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if not result.stdout.strip():
        return []
    try:
        data = json.loads(result.stdout)
        if isinstance(data, dict):
            return [data]
        return data
    except Exception:
        return []

def get_modems():
    cmd = [
        "powershell",
        "-Command",
        "Get-WmiObject Win32_POTSModem | Select-Object Name, DeviceID, AttachedTo | ConvertTo-Json"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if not result.stdout.strip():
        return []
    try:
        data = json.loads(result.stdout)
        if isinstance(data, dict):
            return [data]
        return data
    except Exception:
        return []

def get_serial_ports():
    cmd = [
        "powershell",
        "-Command",
        "Get-WmiObject Win32_SerialPort | Select-Object Name, DeviceID | ConvertTo-Json"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if not result.stdout.strip():
        return []
    try:
        data = json.loads(result.stdout)
        if isinstance(data, dict):
            return [data]
        return data
    except Exception:
        return []

def detect_wwan():
    result = {
        "net_adapters": get_net_adapters(),
        "modems": get_modems(),
        "serial_ports": get_serial_ports()
    }
    with open("wwan_devices.json", "w", encoding="utf-8") as f:
        json.dump(result, f, indent=4, ensure_ascii=False)
    print("Zapisano wwan_devices.json")

if __name__ == "__main__":
    detect_wwan()
