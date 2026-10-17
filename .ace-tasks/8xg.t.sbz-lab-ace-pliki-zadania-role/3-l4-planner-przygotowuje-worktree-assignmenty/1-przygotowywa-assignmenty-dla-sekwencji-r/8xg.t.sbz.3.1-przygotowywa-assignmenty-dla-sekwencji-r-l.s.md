---
id: 8xg.t.sbz.3.1
status: draft
priority: medium
created_at: "2026-10-17 18:54:15"
estimate: medium
dependencies: ["8xg.t.sbz.3.0", "8xg.t.sbz.4"]
tags: ["lab", "lab-l4", "file-based"]
parent: 8xg.t.sbz.3
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-assign/README.md", "ace-git-worktree/docs/usage.md", "ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/8xg.t.sbz.3-l4-planner-przygotowuje-worktree-assignmenty-i-start.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md", ".ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/1-przygotowywa-assignmenty-dla-sekwencji-r/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Przygotowywać assignmenty dla sekwencji ról"
---

# Przygotowywać assignmenty dla sekwencji ról

## Cel

Overseer deleguje przygotowanie, a role otrzymują kompletny kontekst pracy. Ten subtask dostarcza następujący wycinek: Planner przygotowuje assignmenty dla całej znanej sekwencji od razu, korzystając z konfiguracji projektu i ról; określa oczekiwany wynik każdego zlecenia.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Wejście: task i sekwencja ról. Wynik: worktree, assignmenty oraz .ace-local/coworker/ i raport gotowości.

Planner przygotowuje assignmenty dla całej znanej sekwencji od razu, korzystając z konfiguracji projektu i ról; określa oczekiwany wynik każdego zlecenia.

## Kryteria odbioru

- [ ] Worker i reviewer dostają różne procesy, dopasowane do tego samego taska; kolejność i warunki odbioru są jawne.
- [ ] Brak wymaganego procesu projektu/roli jest raportowany, a planner nie podstawia procesu innej roli bez podstaw.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Worker i reviewer dostają różne procesy, dopasowane do tego samego taska; kolejność i warunki odbioru są jawne.
- Scenariusz błędu / niepoprawnego wejścia: Brak wymaganego procesu projektu/roli jest raportowany, a planner nie podstawia procesu innej roli bez podstaw.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L4.1 / 8xg.t.sbz.3.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/3-l4-planner-przygotowuje-worktree-assignmenty/0-przyjmowa-zlecenie-przygotowania-i-zapewnia/8xg.t.sbz.3.0-przyjmowa-zlecenie-przygotowania-i-zapewnia-worktree.s.md), [L5 / 8xg.t.sbz.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
