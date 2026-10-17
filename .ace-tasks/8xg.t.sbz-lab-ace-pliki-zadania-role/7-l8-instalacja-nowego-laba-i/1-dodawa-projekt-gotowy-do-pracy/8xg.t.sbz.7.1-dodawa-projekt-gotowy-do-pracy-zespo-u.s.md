---
id: 8xg.t.sbz.7.1
status: draft
priority: medium
created_at: "2026-10-17 18:54:25"
estimate: medium
dependencies: ["8xg.t.sbz.7.0", "8xg.t.sbz.3", "8xg.t.sbz.5"]
tags: ["lab", "lab-l8", "file-based"]
parent: 8xg.t.sbz.7
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-lab/docs/usage.md", "ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md", "ace-hitl/docs/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/3-ace-lab-project-add-step/8xg.t.qn6.3-ace-lab-project-add-step-by-step.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md", ".ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/1-dodawa-projekt-gotowy-do-pracy/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Dodawać projekt gotowy do pracy zespołu"
---

# Dodawać projekt gotowy do pracy zespołu

## Cel

Nowy lab i projekt są gotowe do pracy właściwych ról pod właściwymi kontami. Ten subtask dostarcza następujący wycinek: ace-lab project add przygotowuje repozytorium, konfigurację projektu, prywatne _overseer, presety ról, komunikację i dane potrzebne plannerowi.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-lab install oraz ace-lab project add; konfiguracja kont, katalogów, kluczy, ról i adapterów; końcowa weryfikacja.

ace-lab project add przygotowuje repozytorium, konfigurację projektu, prywatne _overseer, presety ról, komunikację i dane potrzebne plannerowi.

## Kryteria odbioru

- [ ] Dodany projekt jest widoczny w statusie, a planner może przygotować jego pierwszy task bez ręcznego naprawiania katalogów.
- [ ] Ponowne dodanie nie niszczy konfiguracji ani zmian istniejącego projektu; konflikt lokalizacji jest zgłaszany przed nadpisaniem.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Dodany projekt jest widoczny w statusie, a planner może przygotować jego pierwszy task bez ręcznego naprawiania katalogów.
- Scenariusz błędu / niepoprawnego wejścia: Ponowne dodanie nie niszczy konfiguracji ani zmian istniejącego projektu; konflikt lokalizacji jest zgłaszany przed nadpisaniem.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L8.1 / 8xg.t.sbz.7.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/0-przygotowa-konta-katalogi-uprawnienia-i/8xg.t.sbz.7.0-przygotowa-konta-katalogi-uprawnienia-i-klucze.s.md), [L4 / 8xg.t.sbz.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md), [L6 / 8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md)

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
