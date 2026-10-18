---
id: 8xg.t.sbz.2.1
status: done
priority: medium
created_at: "2026-10-17 18:54:13"
estimate: medium
dependencies: [8xg.t.sbz.2.0]
tags: [lab, lab-l3, file-based]
parent: 8xg.t.sbz.2
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-assign/README.md, ace-assign/docs/usage.md, ace-overseer/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/1-prowadzi-i-rozwija-w-asny/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md, ace-assign/handbook/workflow-instructions/assign/drive.wf.md]
  commands: []
title: Prowadzić i rozwijać własny ace-assign
---

# Prowadzić i rozwijać własny ace-assign

## Cel

Przygotowany wykonawca prowadzi własny assignment i zachowuje postęp. Ten subtask dostarcza następujący wycinek: Coworker prowadzi istniejący ace-assign do końca. Po uruchomieniu może dodawać kroki, naprawy i sprawdzenia w granicach celu i reguł roli.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

Coworker prowadzi istniejący ace-assign do końca. Po uruchomieniu może dodawać kroki, naprawy i sprawdzenia w granicach celu i reguł roli.

## Kryteria odbioru

- [x] Dodane sprawdzenie zostaje częścią tego samego planu, jest wykonane i widoczne przez ace-assign.
- [x] Dodanie kroku nie tworzy drugiej kolejki i nie omija ograniczeń roli ani zależności nadzorowanych przez overseera.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Dodane sprawdzenie zostaje częścią tego samego planu, jest wykonane i widoczne przez ace-assign.
- Scenariusz błędu / niepoprawnego wejścia: Dodanie kroku nie tworzy drugiej kolejki i nie omija ograniczeń roli ani zależności nadzorowanych przez overseera.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L3.1 / 8xg.t.sbz.2.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/0-startowa-z-przygotowanej-konfiguracji-coworkera/8xg.t.sbz.2.0-startowa-z-przygotowanej-konfiguracji-coworkera.s.md)

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

Wykorzystać istniejący workflow drive i komendy ace-assign start/finish/fail/add/retry/status. Rozszerzenie własnego assignmentu pozostaje w tym samym planie. Weryfikować zakończenie wymaganych kroków; pusty/niepoprawny plan lub nieudany krok nie stają się sukcesem przez zakończenie sesji.
Odbiór: przygotowany lokalnie assignment z dodatkowym sprawdzeniem oraz wariant błędu. Komunikacja z odbiorcą jest zakresem .2.2; tutaj wystarcza lokalny wynik. Nie implementować nowego silnika kroków, automatycznego planowania zadań ani reguł konkretnych ról.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
