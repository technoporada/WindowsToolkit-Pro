# SECURITY CHECKLIST

Ten dokument opisuje minimalny, bezpieczny stan roboczy dla repo `WindowsToolkit-Pro`.

## Status
- Status: safe-release / admin hardening
- Cel: ograniczyć ryzyko przypadkowego uszkodzenia systemu i zapewnić bezpieczną politykę wykonywania skryptów.

## KRYTYCZNE
- [ ] Włączyć `Set-StrictMode -Version Latest` we wszystkich głównych skryptach.
- [ ] Dodać `#Requires -RunAsAdministrator` tam, gdzie skrypt modyfikuje system, firewall lub rejestr.
- [ ] Ustalić `-WhatIf` / `-Confirm` support dla operacji zmieniających system.
- [ ] Dodać backup / restore policy dla wpisów rejestru, usług, ustawień systemowych.
- [ ] Dodać bezpieczną politykę `ErrorActionPreference = 'Stop'`.

## WYSOKI PRIORYTET
- [ ] Wprowadzić wspólny moduł narzędzi i funkcji wspólnych (`Common.psm1`, `Admin.psm1`, `Logging.psm1`).
- [ ] Dodać `Test-Path` / walidację przed modyfikacją kluczy systemowych.
- [ ] Dodać `dry run` / `preview mode` dla operacji usuwających lub modyfikujących ustawienia.
- [ ] Ustalić politykę rollback dla `debloat`, `firewall`, `repair`.

## ŚREDNI PRIORYTET
- [ ] Uruchamiać PSScriptAnalyzer i CI dla skryptów.
- [ ] Dodać smoke testy dla kluczowych operacji.
- [ ] Dodać dokumentację: co robi skrypt, co może zmienić, jak cofnąć.

# KNOWN_ISSUES

## P1 – Critical
- Skrypty administracyjne mogą wykonywać zmiany systemu bez jawnej ochrony `admin guard`.
- Brak `WhatIf` i rollbacku dla operacji modyfikujących system.
- Brak spójnej polityki błędów i 