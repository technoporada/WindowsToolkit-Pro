# PATCH PRIORITY

## Cel
Minimalny, bezpieczny, kontrolowany plan poprawy repo bez wielkiego refactoru. Ograniczamy się do tego, co obniża ryzyko, a nie do estetyki kodu.

## Priorytet 1 — zamknąć podatności krytyczne
- [ ] Wymusić `RunAsAdministrator` dla skryptów, które zmieniają system, firewall, rejestr lub usługi.
- [ ] Ustawić `Set-StrictMode` i `ErrorActionPreference = 'Stop'` w głównych skryptach.
- [ ] Dodać `-WhatIf` / `-Confirm` do operacji modyfikujących system.
- [ ] Dodać backup / restore policy dla modyfikacji systemowych.
- [ ] Zabezpieczyć skrypty przed uruchomieniem bez zrozumienia skutków.

## Priorytet 2 — poprawić bezpieczeństwo danych
- [ ] Dodać politykę dry run / preview dla debloatów i repairów.
- [ ] Zabezpieczyć import i export danych systemowych.
- [ ] Dodać logowanie wykonanych operacji i zatwierdzonych zmian.

## Priorytet 3 — minimalne uszlachetnienie architektury
- [ ] Wprowadzić wspólny moduł funkcji wspólnych (`Common.psm1`, `Admin.psm1`, `Logging.psm1`).
- [ ] Dodać prostą walidację danych wejściowych dla skryptów.
- [ ] Dodać podstawową dokumentację rollbacku.

## Priorytet 4 — clean-up / quality
- [ ] Dodać PSScriptAnalyzer i CI dla skryptów.
- [ ] Dodać smoke testy dla kluczowych operacji.
- [ ] Zostawić wybiórcze, ograniczone komentarze, nie “full dokumentację wszystkiego”.

## Reguła:
Jeśli coś modyfikuje system bezpiecznie tylko przy admin rights / restore point, to jest pierwszeństwo. Estetyka skryptów nie ma znaczenia dopóki operacja nie jest bezpieczna.
