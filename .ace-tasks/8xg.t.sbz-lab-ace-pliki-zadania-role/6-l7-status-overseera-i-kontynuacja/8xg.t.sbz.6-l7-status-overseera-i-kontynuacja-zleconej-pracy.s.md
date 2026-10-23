---
id: 8xg.t.sbz.6
status: in-progress
priority: high
created_at: "2026-10-17 18:53:36"
estimate: large
dependencies: []
tags: [lab, lab-l7, file-based]
parent: 8xg.t.sbz
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-overseer/docs/usage.md, ace-herdr/README.md, ace-git-worktree/docs/usage.md, ace-handbook-integration-pi/handbook/extensions/ace-wake/index.js, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/0-ace-herdr-status-spaces-tabs/8xg.t.qn6.0-ace-herdr-status-spaces-tabs-and-panes.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/1-ace-lab-status-lab-configuration/8xg.t.qn6.1-ace-lab-status-lab-configuration-and-state.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md, .ace-tasks/_archive/8x/x/8xd.t.cm3-durable-goal-capability-for-pi/8xd.t.cm3-durable-goal-capability-for-pi-agents-objective.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/ux/usage.md, .ace-tasks/8xg.t.k9y-ace-git-worktree-list-active/8xg.t.k9y-ace-git-worktree-list-active-worktree-table.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md]
  commands: []
title: "L7: Status overseera i kontynuacja zleconej pracy w pi"
---

# L7: Status overseera i kontynuacja zleconej pracy w pi

## Cel i zachowanie

Overseer widzi rzeczywistą sytuację i kontynuuje już zlecony proces po wiadomości lub restarcie.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

ace-overseer status, ace-lab status, ace-herdr status oraz istniejące ace-git-worktree list; konfiguracja źródeł i kontynuacja w pi.

## Subtaski i kolejność

- [8xg.t.sbz.6.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/0-udost-pni-statusy-laba-herdr/8xg.t.sbz.6.0-udost-pni-statusy-laba-herdr-i-worktree.s.md) — Dostarczyć ace-herdr status pokazujący spaces/tabs/panes oraz ace-lab status czytający konfigurację i pliki. Widok worktree oprzeć na ukończonym k9y i obecnym ace-git-worktree list.
- [8xg.t.sbz.6.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/1-zebra-konfigurowalny-status-overseera/8xg.t.sbz.6.1-zebra-konfigurowalny-status-overseera.s.md) — ace-overseer status zbiera konfigurowalne źródła: PR/issues GitHub lub Forgejo, projektowy ace-task, _overseer, worktree, Herdr i postęp coworkerów.
- [8xg.t.sbz.6.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/2-kontynuowa-zlecon-prac-w-pi/8xg.t.sbz.6.2-kontynuowa-zlecon-prac-w-pi.s.md) — Mechanizmy w pi przyjmują wiadomości podczas pracy i oczekiwania oraz wznawiają zlecony proces. Po restarcie overseer czyta _overseer i aktualną prawdę o projekcie.
- [8xg.t.sbz.6.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/3-pokazywa-blokady-awarie-i-brak/8xg.t.sbz.6.3-pokazywa-blokady-awarie-i-brak-danych.s.md) — Status i instrukcje rozróżniają pracę trwającą, zakończoną, oczekującą na decyzję, przerwaną oraz brak informacji. Zachowują opis przeszkody i następnego działania.

## Kryteria odbioru

- [ ] Bez starego procesu właściciela laba widać konfigurację i lokalny stan; Herdr pokazuje rzeczywisty układ, a worktree zachowują skojarzenia z taskami.
- [ ] Overseer z jednego widoku rozpoznaje trwające kroki, gotową pracę, zależności i dostępne zasoby; wyłączenie źródła w konfiguracji jest respektowane.
- [ ] Raport budzi oczekującego overseera; po restarcie kontynuuje on ten sam proces i istniejące assignmenty.
- [ ] Overseer widzi, na czyją decyzję lub jaki wynik czeka, i może kontynuować po usunięciu przeszkody.

## Weryfikacja i scenariusze błędów

- Nieobecny runtime lub niepełna konfiguracja są oznaczone, a nie przedstawione jako pusty i gotowy lab. Nie dublować funkcji k9y.
- Awaria źródła jest pokazana obok dostępnych wyników; brak danych nie staje się potwierdzeniem wolnego worktree lub zakończonego zadania.
- Powtórzone powiadomienia nie tworzą drugiej egzekucji; brak nowej zleconej pracy nie prowadzi do samodzielnego szukania kolejnych zadań.
- Niedostępny forge, agent lub plik nie jest sukcesem ani sygnałem do uruchomienia zastępczej pracy na tym samym worktree.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

To grupa odbioru. Start konkretnych prac określają dependencies jej liści; puste dependencies rodzica nie odblokowują wszystkich dzieci. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Gotowość specyfikacji i możliwość startu są odrębne: po review sprawdzić dependencies konkretnego liścia. Samo pending nie usuwa zależności.
Rozmiar orientacyjny: large. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.0](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/0-ace-herdr-status-spaces-tabs/8xg.t.qn6.0-ace-herdr-status-spaces-tabs-and-panes.s.md)
- [8xg.t.qn6.1](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/1-ace-lab-status-lab-configuration/8xg.t.qn6.1-ace-lab-status-lab-configuration-and-state.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)
- [8xd.t.cm3](.ace-tasks/_archive/8x/x/8xd.t.cm3-durable-goal-capability-for-pi/8xd.t.cm3-durable-goal-capability-for-pi-agents-objective.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Status worktree korzysta z ukończonego `8xg.t.k9y`; obecnym publicznym wejściem jest `ace-git-worktree list`. Nie tworzyć drugiej implementacji tylko dla nazwy status. L7.1 może być wykonany wcześniej niż cała rodzina L7.

## Review gotowości — 2026-10-18, po PR #379

Wszystkie dzieci objęto review osobno. Pending oznacza gotową specyfikację, nie ukończoną funkcję ani zniesienie dependencies. Zlecenie tej grupy rozpoczyna się od dostępnych liści według execution-order.md; późniejsza blokada nie zatrzymuje wcześniejszego zakresu. Jeden główny zakres ma jedno worktree, role i subtaski pracują kolejno, a potrzebne poprzednikom fragmenty można integrować osobnymi PR-ami.

Źródła: `docs/lab-flow.md`, ADR-034 i review poszczególnych dzieci.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.

## Ponowne otwarcie L7 — 2026-10-23

Rodzina jest ponownie `in-progress` z powodu przygotowania nowego draftu
`8xg.t.sbz.6.2`: zdarzeniowe oczy, brak tur LLM bez zmiany, budżet bezczynności
oraz blokada quota. Szczegółowy kontrakt i wszystkie nowe kryteria są wyłącznie
w tym liściu; wcześniejsze dowody L7 pozostają zachowane. Nie oznacza to nowej
implementacji ani zgody na ponowne włączenie odstawionych pętli.
