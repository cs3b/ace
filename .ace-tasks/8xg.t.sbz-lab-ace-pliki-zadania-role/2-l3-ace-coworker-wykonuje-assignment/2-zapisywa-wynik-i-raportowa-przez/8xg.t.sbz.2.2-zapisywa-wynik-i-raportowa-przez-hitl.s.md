---
id: 8xg.t.sbz.2.2
status: done
priority: medium
created_at: "2026-10-17 18:54:13"
estimate: medium
dependencies: [8xg.t.sbz.2.1, 8xg.t.sbz.1]
tags: [lab, lab-l3, file-based]
parent: 8xg.t.sbz.2
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-assign/README.md, ace-assign/docs/usage.md, ace-overseer/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/2-zapisywa-wynik-i-raportowa-przez/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md, ace-hitl/README.md]
  commands: []
title: Zapisywać wynik i raportować przez HITL
---

# Zapisywać wynik i raportować przez HITL

## Cel

Przygotowany wykonawca prowadzi własny assignment i zachowuje postęp. Ten subtask dostarcza następujący wycinek: Trwały postęp zapisuje się przy tasku, pomocniczy stan w .ace-local/coworker/. Po zakończeniu assignmentu albo błędzie coworker raportuje przez ace-hitl.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

Trwały postęp zapisuje się przy tasku, pomocniczy stan w .ace-local/coworker/. Po zakończeniu assignmentu albo błędzie coworker raportuje przez ace-hitl.

## Kryteria odbioru

- [x] Zakończony assignment pozostawia wynik i raport do overseera; błąd zawiera przyczynę i stan umożliwiający dalsze działanie.
- [x] Samo zakończenie procesu lub wysłanie raportu nie oznacza wykonania nieukończonych kroków; niedostarczenie raportu nie gubi lokalnego wyniku.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Zakończony assignment pozostawia wynik i raport do overseera; błąd zawiera przyczynę i stan umożliwiający dalsze działanie.
- Scenariusz błędu / niepoprawnego wejścia: Samo zakończenie procesu lub wysłanie raportu nie oznacza wykonania nieukończonych kroków; niedostarczenie raportu nie gubi lokalnego wyniku.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L3.2 / 8xg.t.sbz.2.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/1-prowadzi-i-rozwija-w-asny/8xg.t.sbz.2.1-prowadzi-i-rozwija-w-asny-ace-assign.s.md), [L2 / 8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md)

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

Po integracji .1 i .2.1 raport zawiera ID taska, assignmentu i kroku oraz wynik i odnośnik do lokalnych dowodów. Trwały wynik pracy trafia do folderu taska; pomocniczy stan wykonawcy do `.ace-local/coworker/`, a wiadomość do HITL przez jego interfejs.
Oddzielić wynik wykonania od dostarczenia: poprawnie ukończony assignment z niedostarczonym raportem zachowuje sukces pracy i jawny błąd dostarczenia. Błąd wykonania zapisuje przyczynę i niedokończony krok, nie fałszywe work done. Sprawdzić oba przypadki z odbiorcą testowym; nie wymagać gotowego .5.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-hitl/README.md`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
