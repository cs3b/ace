---
id: 8xg.t.sbz.7.2
status: draft
priority: medium
created_at: "2026-10-17 18:54:25"
estimate: medium
dependencies: ["8xg.t.sbz.7.1"]
tags: ["lab", "lab-l8", "file-based"]
parent: 8xg.t.sbz.7
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-lab/docs/usage.md", "ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md", "ace-hitl/docs/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/3-ace-lab-project-add-step/8xg.t.qn6.3-ace-lab-project-add-step-by-step.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md", ".ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/2-przeprowadza-instalacj-nowego-laba/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Przeprowadzać instalację nowego laba"
---

# Przeprowadzać instalację nowego laba

## Cel

Nowy lab i projekt są gotowe do pracy właściwych ról pod właściwymi kontami. Ten subtask dostarcza następujący wycinek: ace-lab install prowadzi nową instalację przez konta, katalogi, konfigurację, adaptery HITL, klucze i weryfikację; korzysta z paczek ACE.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

ace-lab install prowadzi nową instalację przez konta, katalogi, konfigurację, adaptery HITL, klucze i weryfikację; korzysta z paczek ACE.

## Kryteria odbioru

- [ ] Na świeżym środowisku kończy instalację gotową do project add i uruchomienia coworkera.
- [ ] Gotowy lub obcy lab powoduje odmowę nadpisania; brak wymaganych uprawnień/narzędzi jest konkretnie zgłoszony, bez pozornego sukcesu.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Na świeżym środowisku kończy instalację gotową do project add i uruchomienia coworkera.
- Scenariusz błędu / niepoprawnego wejścia: Gotowy lub obcy lab powoduje odmowę nadpisania; brak wymaganych uprawnień/narzędzi jest konkretnie zgłoszony, bez pozornego sukcesu.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L8.2 / 8xg.t.sbz.7.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/1-dodawa-projekt-gotowy-do-pracy/8xg.t.sbz.7.1-dodawa-projekt-gotowy-do-pracy-zespo-u.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.3](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/3-ace-lab-project-add-step/8xg.t.qn6.3-ace-lab-project-add-step-by-step.s.md)
- [8xg.t.qn6.5](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md)
- [8xb.t.iy6](.ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
