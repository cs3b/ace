---
id: 8xg.t.sbz.2.3
status: done
priority: medium
created_at: "2026-10-17 18:54:14"
estimate: medium
dependencies: [8xg.t.sbz.2.2]
tags: [lab, lab-l3, file-based]
parent: 8xg.t.sbz.2
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-assign/README.md, ace-assign/docs/usage.md, ace-overseer/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/3-wznawia-assignment-z-istniej-cego/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md, ace-assign/handbook/workflow-instructions/assign/drive.wf.md]
  commands: []
title: Wznawiać assignment z istniejącego worktree
---

# Wznawiać assignment z istniejącego worktree

## Cel

Przygotowany wykonawca prowadzi własny assignment i zachowuje postęp. Ten subtask dostarcza następujący wycinek: Po przerwaniu odczytać istniejący assignment, task i rzeczywisty stan tego samego worktree; kontynuować niedokończoną pracę.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

Po przerwaniu odczytać istniejący assignment, task i rzeczywisty stan tego samego worktree; kontynuować niedokończoną pracę.

## Kryteria odbioru

- [x] Restart w połowie zlecenia zachowuje ukończone kroki i lokalne zmiany oraz wraca do pracy pozostałej do wykonania.
- [x] Jeżeli nie wiadomo, czy merge/publikacja zaszły, sprawdzić ich stan lub zgłosić blokadę zamiast ślepo wykonywać je ponownie; nie tworzyć nowego taska/worktree.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Restart w połowie zlecenia zachowuje ukończone kroki i lokalne zmiany oraz wraca do pracy pozostałej do wykonania.
- Scenariusz błędu / niepoprawnego wejścia: Jeżeli nie wiadomo, czy merge/publikacja zaszły, sprawdzić ich stan lub zgłosić blokadę zamiast ślepo wykonywać je ponownie; nie tworzyć nowego taska/worktree.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L3.3 / 8xg.t.sbz.2.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/2-zapisywa-wynik-i-raportowa-przez/8xg.t.sbz.2.2-zapisywa-wynik-i-raportowa-przez-hitl.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Gotowość specyfikacji i możliwość startu są odrębne: po review sprawdzić dependencies konkretnego liścia. Samo pending nie usuwa zależności.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.2](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Wznowienie korzysta z tego samego taska, assignmentu i worktree; ukończone kroki pozostają ukończone. Przerwany krok jest oceniany na podstawie obecnego stanu plików/Gita i swojego raportu przed ponowieniem skutku. Nie resetować lokalnych zmian.
Dla niejednoznacznego merge/publikacji odczytać faktyczny stan istniejącym narzędziem albo zgłosić blokadę. Jeśli assignment jest już ukończony, a brak jedynie dostarczenia, ponowić wiadomość HITL o tym samym ID. Test przerwania w połowie oraz po wykonaniu skutku przed zapisem wyniku; bez nowego journala/checkpoint store.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
