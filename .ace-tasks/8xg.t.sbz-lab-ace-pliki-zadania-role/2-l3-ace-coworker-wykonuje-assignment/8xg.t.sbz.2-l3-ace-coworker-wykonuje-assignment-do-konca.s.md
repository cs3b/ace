---
id: 8xg.t.sbz.2
status: in-progress
priority: high
created_at: "2026-10-17 18:53:34"
estimate: large
dependencies: []
tags: [lab, lab-l3, file-based]
parent: 8xg.t.sbz
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-assign/README.md, ace-assign/docs/usage.md, ace-overseer/README.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md]
  commands: []
title: "L3: Ace-coworker wykonuje assignment do końca lub zgłasza błąd"
---

# L3: Ace-coworker wykonuje assignment do końca lub zgłasza błąd

## Cel i zachowanie

Przygotowany wykonawca prowadzi własny assignment i zachowuje postęp.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

## Subtaski i kolejność

- [8xg.t.sbz.2.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/0-startowa-z-przygotowanej-konfiguracji-coworkera/8xg.t.sbz.2.0-startowa-z-przygotowanej-konfiguracji-coworkera.s.md) — Start coworkera czyta .ace-local/coworker/: rolę, źródło instrukcji, prompt startowy, task, istniejący assignment, adres overseera oraz zasady błędów.
- [8xg.t.sbz.2.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/1-prowadzi-i-rozwija-w-asny/8xg.t.sbz.2.1-prowadzi-i-rozwija-w-asny-ace-assign.s.md) — Coworker prowadzi istniejący ace-assign do końca. Po uruchomieniu może dodawać kroki, naprawy i sprawdzenia w granicach celu i reguł roli.
- [8xg.t.sbz.2.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/2-zapisywa-wynik-i-raportowa-przez/8xg.t.sbz.2.2-zapisywa-wynik-i-raportowa-przez-hitl.s.md) — Trwały postęp zapisuje się przy tasku, pomocniczy stan w .ace-local/coworker/. Po zakończeniu assignmentu albo błędzie coworker raportuje przez ace-hitl.
- [8xg.t.sbz.2.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/3-wznawia-assignment-z-istniej-cego/8xg.t.sbz.2.3-wznawia-assignment-z-istniej-cego-worktree.s.md) — Po przerwaniu odczytać istniejący assignment, task i rzeczywisty stan tego samego worktree; kontynuować niedokończoną pracę.

## Kryteria odbioru

- [ ] Wykonawca startuje w przygotowanym worktree z właściwą rolą i dokładnie wskazanym assignmentem.
- [ ] Dodane sprawdzenie zostaje częścią tego samego planu, jest wykonane i widoczne przez ace-assign.
- [ ] Zakończony assignment pozostawia wynik i raport do overseera; błąd zawiera przyczynę i stan umożliwiający dalsze działanie.
- [ ] Restart w połowie zlecenia zachowuje ukończone kroki i lokalne zmiany oraz wraca do pracy pozostałej do wykonania.

## Weryfikacja i scenariusze błędów

- Brak instrukcji roli, taska albo assignmentu daje konkretny błąd; coworker nie zgaduje innego zlecenia.
- Dodanie kroku nie tworzy drugiej kolejki i nie omija ograniczeń roli ani zależności nadzorowanych przez overseera.
- Samo zakończenie procesu lub wysłanie raportu nie oznacza wykonania nieukończonych kroków; niedostarczenie raportu nie gubi lokalnego wyniku.
- Jeżeli nie wiadomo, czy merge/publikacja zaszły, sprawdzić ich stan lub zgłosić blokadę zamiast ślepo wykonywać je ponownie; nie tworzyć nowego taska/worktree.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

To grupa odbioru. Start konkretnych prac określają dependencies jej liści; puste dependencies rodzica nie odblokowują wszystkich dzieci. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Gotowość specyfikacji i możliwość startu są odrębne: po review sprawdzić dependencies konkretnego liścia. Samo pending nie usuwa zależności.
Rozmiar orientacyjny: large. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.2](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Wszystkie dzieci objęto review osobno. Pending oznacza gotową specyfikację, nie ukończoną funkcję ani zniesienie dependencies. Zlecenie tej grupy rozpoczyna się od dostępnych liści według execution-order.md; późniejsza blokada nie zatrzymuje wcześniejszego zakresu. Jeden główny zakres ma jedno worktree, role i subtaski pracują kolejno, a potrzebne poprzednikom fragmenty można integrować osobnymi PR-ami.

Źródła: `docs/lab-flow.md`, ADR-034 i review poszczególnych dzieci.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
