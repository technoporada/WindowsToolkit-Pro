# winopt-launcher.ps1
# Run as Administrator:
# Set-ExecutionPolicy Bypass -Scope Process
# .\winopt-launcher.ps1

# -------------- SCAN --------------
$results = [ordered]@{}

# 1) Appx packages (All Users)
Try {
    $apps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object -Property Name,PackageFullName,InstallLocation -Unique
} Catch {
    $apps = @()
}
$results.Apps = @()
foreach($a in $apps){
    $results.Apps += [ordered]@{
        Name = ($a.Name -replace "`r|`n","")
        PackageFullName = ($a.PackageFullName -replace "`r|`n","")
        InstallLocation = ($a.InstallLocation -replace "`r|`n","")
    }
}

# 2) Services of interest (example list)
$servicesCheck = @("DiagTrack","WSearch","W32Time")
$results.Services = @()
foreach($s in $servicesCheck){
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    if($svc){
        $results.Services += [ordered]@{ Name = $svc.Name; Status = $svc.Status.ToString() }
    } else {
        $results.Services += [ordered]@{ Name = $s; Status = "NotFound" }
    }
}

# 3) PATH entries (Machine)
$path = [Environment]::GetEnvironmentVariable("PATH","Machine")
$entries = @()
if($path){
    $entries = $path -split ';' | Where-Object { $_ -and $_ -ne '' }
}
$results.Path = @()
foreach($p in $entries){
    $exists = Test-Path $p -ErrorAction SilentlyContinue
    $results.Path += [ordered]@{ Entry = $p; Exists = $exists }
}

# 4) Listening TCP ports (try)
Try {
    $tcp = Get-NetTCPConnection -State Listen -ErrorAction Stop | Select-Object -Property LocalPort,LocalAddress -Unique
    $results.Listening = @()
    foreach($t in $tcp){ $results.Listening += [ordered]@{ Port = $t.LocalPort; Addr = $t.LocalAddress } }
} Catch {
    $results.Listening = @()
}

# -------------- PREPARE HTML --------------
$json = $results | ConvertTo-Json -Depth 6
# encode to base64 to safely embed in HTML
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
$b64 = [Convert]::ToBase64String($bytes)

$timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$outHtml = Join-Path $env:TEMP ("winopt-$timestamp.html")

$html = @"
<!doctype html>
<html lang="pl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Win Optimizer — Local Viewer</title>
<style>
body{font-family:Segoe UI,Arial,Helvetica;background:#081224;color:#e6eef6;margin:16px}
.container{max-width:1100px;margin:0 auto}
.card{background:#071423;padding:14px;border-radius:8px;margin-bottom:12px;border:1px solid rgba(255,255,255,0.03)}
h1{margin:0 0 6px 0;font-size:1.3rem}
.small{color:#98a6b6;font-size:0.9rem}
.table{width:100%;border-collapse:collapse;margin-top:8px}
.table th,.table td{padding:8px;border-bottom:1px solid rgba(255,255,255,0.02);text-align:left}
.btn{background:#16a34a;color:#04111a;border:none;padding:8px 10px;border-radius:8px;cursor:pointer}
.btn.ghost{background:transparent;border:1px solid rgba(255,255,255,0.04);color:#98a6b6}
.preview{white-space:pre-wrap;background:#041018;padding:10px;border-radius:6px;max-height:320px;overflow:auto;color:#cfeed1}
.smallmuted{color:#98a6b6;font-size:0.85rem}
.bad{color:#ff7b7b}
.good{color:#9ef08a}
.controls{display:flex;gap:8px;flex-wrap:wrap;margin-top:10px}
</style>
</head>
<body>
<div class="container">
  <div class="card">
    <h1>Win Optimizer — Local Viewer</h1>
    <div class="small">Wyniki przeskanowanego systemu. Nic tu nie jest wykonywane automatycznie. Po wyborze generuj pliki .ps1 do pobrania i sprawdzenia.</div>
    <div class="smallmuted" style="margin-top:8px">Plik wygenerowany lokalnie przez PowerShell. Data: $timestamp</div>
  </div>

  <div class="card" id="resultsCard">
    <div><strong>Apps (Appx)</strong></div>
    <table class="table" id="appsTable">
      <thead><tr><th></th><th>Package</th><th class="small">FullName / InstallLocation</th></tr></thead>
      <tbody></tbody>
    </table>

    <div style="margin-top:10px"><strong>Services</strong></div>
    <table class="table" id="svcTable"><thead><tr><th></th><th>Service</th><th class="small">State</th></tr></thead><tbody></tbody></table>

    <div style="margin-top:10px"><strong>PATH entries</strong></div>
    <table class="table" id="pathTable"><thead><tr><th></th><th>Entry</th><th class="small">Exists</th></tr></thead><tbody></tbody></table>

    <div style="margin-top:10px"><strong>Listening</strong></div>
    <table class="table" id="listenTable"><thead><tr><th>Port</th><th>Addr</th></tr></thead><tbody></tbody></table>

    <div class="controls">
      <button class="btn" id="genApply">Generuj apply.ps1</button>
      <button class="btn ghost" id="genUndo">Generuj undo.ps1</button>
      <button class="btn ghost" id="previewBtn">Preview skryptu</button>
      <button class="btn ghost" id="downloadBoth">Pobierz oba</button>
    </div>

    <div style="margin-top:12px">
      <div class="small">Podglad / Log</div>
      <div class="preview" id="preview"></div>
    </div>
  </div>

  <div class="card smallmuted">Instrukcja: po wygenerowaniu pobierz pliki i uruchom je recznie w PowerShell jako Administrator. Uzyj: <code>Set-ExecutionPolicy Bypass -Scope Process</code> przed uruchomieniem. Zawsze zrob backup/punkt przywracania.</div>
</div>

<script>
// decode base64 JSON provided by launcher
(function(){
  const b64 = "$b64";
  let json = "{}";
  try {
    const txt = atob(b64);
    json = txt;
  } catch(e){
    alert('Blad dekodowania danych skanu: '+e.message);
  }
  const data = JSON.parse(json);

  const appsT = document.querySelector('#appsTable tbody');
  const svcT = document.querySelector('#svcTable tbody');
  const pathT = document.querySelector('#pathTable tbody');
  const listenT = document.querySelector('#listenTable tbody');
  const preview = document.getElementById('preview');

  function addRow(table, inner){ const tr = document.createElement('tr'); tr.innerHTML = inner; table.appendChild(tr); }

  if(data.Apps && data.Apps.length){
    data.Apps.forEach((a,i)=>{
      addRow(appsT, `<td><input type="checkbox" data-type="app" data-idx="${i}"></td><td title="${a.InstallLocation||''}">${a.Name}</td><td class="small">${a.PackageFullName||''}</td>`);
    });
  } else {
    addRow(appsT, `<td colspan="3" class="smallmuted">No appx packages found or access denied.</td>`);
  }

  if(data.Services && data.Services.length){
    data.Services.forEach((s,i)=>{
      addRow(svcT, `<td><input type="checkbox" data-type="svc" data-idx="${i}"></td><td>${s.Name}</td><td class="small">${s.Status}</td>`);
    });
  } else {
    addRow(svcT, `<td colspan="3" class="smallmuted">No services found.</td>`);
  }

  if(data.Path && data.Path.length){
    data.Path.forEach((p,i)=>{
      const exists = p.Exists ? '<span class="good">yes</span>' : '<span class="bad">no</span>';
      addRow(pathT, `<td><input type="checkbox" data-type="path" data-idx="${i}"></td><td title="${p.Entry}">${p.Entry}</td><td class="small">${exists}</td>`);
    });
  } else {
    addRow(pathT, `<td colspan="3" class="smallmuted">PATH empty or access denied.</td>`);
  }

  if(data.Listening && data.Listening.length){
    data.Listening.forEach(l=> addRow(listenT, `<td>${l.Port}</td><td>${l.Addr}</td>`));
  } else {
    addRow(listenT, `<td colspan="2" class="smallmuted">No listening ports or access denied.</td>`);
  }

  function collectSelections(){
    const sel = { apps:[], services:[], pathRemove:[] };
    document.querySelectorAll('input[type=checkbox]').forEach(cb=>{
      if(!cb.checked) return;
      const t = cb.dataset.type; const idx = parseInt(cb.dataset.idx,10);
      if(t==='app') sel.apps.push(data.Apps[idx]);
      if(t==='svc') sel.services.push(data.Services[idx]);
      if(t==='path') sel.pathRemove.push(data.Path[idx]);
    });
    return sel;
  }

  function makeApplyScript(sel){
    let out = "# Apply script generated by Win Optimizer (local)\\n# Run as Administrator\\n\\n";
    if(sel.apps.length){
      out += "# Remove selected Appx packages\\n";
      sel.apps.forEach(a=>{
        out += "Try { Get-AppxPackage -AllUsers -Name \""+a.Name+"\" | Remove-AppxPackage -ErrorAction SilentlyContinue; Write-Output 'REMOVED: "+a.Name+"' } Catch { Write-Output 'FAILED: "+a.Name+"' }\\n";
      });
      out += "\\n";
    }
    if(sel.services.length){
      out += "# Disable selected services\\n";
      sel.services.forEach(s=>{
        out += "Try { Stop-Service -Name \""+s.Name+"\" -Force -ErrorAction SilentlyContinue; Set-Service -Name \""+s.Name+"\" -StartupType Disabled -ErrorAction SilentlyContinue; Write-Output 'SERVICE DISABLED: "+s.Name+"' } Catch { Write-Output 'SERVICE FAILED: "+s.Name+"' }\\n";
      });
      out += "\\n";
    }
    if(sel.pathRemove.length){
      out += "# Remove PATH entries from Machine PATH\\n$old = [Environment]::GetEnvironmentVariable('PATH','Machine')\\n$parts = $old -split ';' | Where-Object { $_ -and $_ -ne '' }\\n";
      sel.pathRemove.forEach(p=> {
        out += "$parts = $parts | Where-Object { $_ -ne \""+p.Entry.replace(/\"/g,'\\"')+"\" }\\n";
      });
      out += "[Environment]::SetEnvironmentVariable('PATH',($parts -join ';'),'Machine')\\nWrite-Output 'PATH updated'\\n\\n";
    }
    if(out.trim()==="# Apply script generated by Win Optimizer (local)\\n# Run as Administrator"){
      out += "Write-Output 'No selections made. Nothing to do.'\\n";
    }
    return out;
  }

  function makeUndoScript(sel){
    let out = "# Undo script generated by Win Optimizer (local)\\n# Note: app reinstall may require Store or DISM\\n\\n";
    if(sel.pathRemove.length){
      out += "# Restore PATH entries (append entries back)\\n$old = [Environment]::GetEnvironmentVariable('PATH','Machine')\\n$parts = $old -split ';' | Where-Object { $_ -and $_ -ne '' }\\n";
      sel.pathRemove.forEach(p=> { out += "$parts += \""+p.Entry.replace(/\"/g,'\\"')+"\"\\n"; });
      out += "[Environment]::SetEnvironmentVariable('PATH',($parts -join ';'),'Machine')\\nWrite-Output 'PATH restored (entries appended)'\\n\\n";
    }
    if(sel.services.length){
      out += "# Re-enable services (set to Manual)\\n";
      sel.services.forEach(s=> { out += "Try { Set-Service -Name \""+s.Name+"\" -StartupType Manual -ErrorAction SilentlyContinue; Write-Output 'SERVICE ENABLED: "+s.Name+"' } Catch { Write-Output 'SERVICE FAILED: "+s.Name+"' }\\n"; });
      out += "\\n";
    }
    if(out.trim()==="# Undo script generated by Win Optimizer (local)\\n# Note: app reinstall may require Store or DISM"){
      out += "Write-Output 'No undo steps available for app removal. Use Store or DISM to reinstall.'\\n";
    }
    return out;
  }

  document.getElementById('genApply').addEventListener('click', ()=> {
    const sel = collectSelections();
    const txt = makeApplyScript(sel);
    preview.textContent = txt;
    const blob = new Blob([txt], {type:'text/plain;charset=utf-8'});
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = 'apply.ps1'; a.click(); URL.revokeObjectURL(url);
  });

  document.getElementById('genUndo').addEventListener('click', ()=> {
    const sel = collectSelections();
    const txt = makeUndoScript(sel);
    preview.textContent = txt;
    const blob = new Blob([txt], {type:'text/plain;charset=utf-8'});
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = 'undo.ps1'; a.click(); URL.revokeObjectURL(url);
  });

  document.getElementById('downloadBoth').addEventListener('click', ()=> {
    const sel = collectSelections();
    const apply = makeApplyScript(sel);
    const undo = makeUndoScript(sel);
    // download both
    const blob1 = new Blob([apply], {type:'text/plain;charset=utf-8'});
    const url1 = URL.createObjectURL(blob1); const a1 = document.createElement('a'); a1.href = url1; a1.download = 'apply.ps1'; a1.click(); URL.revokeObjectURL(url1);
    const blob2 = new Blob([undo], {type:'text/plain;charset=utf-8'});
    const url2 = URL.createObjectURL(blob2); const a2 = document.createElement('a'); a2.href = url2; a2.download = 'undo.ps1'; a2.click(); URL.revokeObjectURL(url2);
    preview.textContent = apply + '\\n\\n--- UNDO ---\\n\\n' + undo;
  });

  document.getElementById('previewBtn').addEventListener('click', ()=> {
    const sel = collectSelections();
    const txt = makeApplyScript(sel);
    preview.textContent = txt;
    window.scrollTo(0,document.body.scrollHeight);
  });

})();
</script>
</body>
</html>
"@

# write html
Try {
    [System.IO.File]::WriteAllText($outHtml, $html, [System.Text.Encoding]::UTF8)
    Write-Host "Wygenerowano plik HTML z wynikami:" $outHtml
    Start-Process $outHtml
} Catch {
    Write-Host "Nie udalo sie zapisac lub otworzyc pliku HTML: $($_.Exception.Message)"
}
