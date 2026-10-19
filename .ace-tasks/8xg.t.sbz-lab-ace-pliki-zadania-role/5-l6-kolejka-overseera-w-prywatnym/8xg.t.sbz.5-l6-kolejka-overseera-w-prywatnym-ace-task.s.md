---
id: 8xg.t.sbz.5
status: done
priority: high
created_at: "2026-10-17 18:53:35"
estimate: large
dependencies: []
tags: [lab, lab-l6, file-based]
parent: 8xg.t.sbz
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-task/docs/usage.md, ace-overseer/README.md, ace-overseer/docs/usage.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md]
  commands: []
title: "L6: Kolejka overseera w prywatnym ace-task"
---

# L6: Kolejka overseera w prywatnym ace-task

## Cel i zachowanie

Drzewo _overseer określa kolejność, zależności i przydziały bez drugiego silnika kolejki.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

Prywatny ace-task --in _overseer, istniejące subtaski/dependencies oraz raporty ace-hitl powiązane z konkretnym krokiem.

## Subtaski i kolejność

- [8xg.t.sbz.5.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/0-zapewni-prywatn-nietrackowan-list-overseera/8xg.t.sbz.5.0-zapewni-prywatn-nietrackowan-list-overseera.s.md) — Zapewnić lokalną listę ace-task --in _overseer zarządzaną wyłącznie przez jej overseera, poza Git i odrębną od tasków projektowych.
- [8xg.t.sbz.5.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/1-zapisywa-proces-wykonania-w-subtaskach/8xg.t.sbz.5.1-zapisywa-proces-wykonania-w-subtaskach.s.md) — Otrzymany zakres pracy zapisać jako task zarządzający z subtaskami przygotowania, implementacji, review, integracji i kolejnych kroków wymaganych przez projekt.
- [8xg.t.sbz.5.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/2-uruchamia-wy-cznie-kroki-odblokowane/8xg.t.sbz.5.2-uruchamia-wy-cznie-kroki-odblokowane-zale-no.s.md) — Uruchamiać tylko subtaski, których zależności są spełnione. Wymóg wcześniejszego merge modelować przez zależność od kroku integracji, nie od samego końca implementacji.
- [8xg.t.sbz.5.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/3-przekazywa-worktree-kolejnym-wykonawcom/8xg.t.sbz.5.3-przekazywa-worktree-kolejnym-wykonawcom.s.md) — Overseer przydziela kolejne role do tego samego worktree zadania i pilnuje jednego aktywnego wykonawcy. Dostępność wynika z przydziałów i rzeczywistego stanu.
- [8xg.t.sbz.5.4](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/4-przetwarza-raporty-i-kontynuowa-kolejk/8xg.t.sbz.5.4-przetwarza-raporty-i-kontynuowa-kolejk.s.md) — Powiązać raport z właściwym taskiem i krokiem, zapisać go w prywatnym zadaniu zarządzającym, następnie uruchomić kolejny odblokowany krok lub obsłużyć błąd.

## Kryteria odbioru

- [x] Po zapisie i wznowieniu lista jest dostępna dla właściciela; git status nie pokazuje jej jako plików do commitu.
- [x] Drzewo pokazuje kolejność i powiązania z zadaniami projektowymi, worktree oraz assignmentami ról.
- [ ] Zadanie B czeka na integrację A mimo ukończenia workera A, a po potwierdzeniu integracji staje się odblokowane.
- [ ] Worker kończy, następnie startuje reviewer, potem integrator; dwa różne taski mogą korzystać z różnych worktree.
- [ ] Jeden realny obieg planner → worker → raport → reviewer działa już w L6; wyniki aktualizują właściwy task nadrzędny.

## Weryfikacja i scenariusze błędów

- Coworker raportuje przez wiadomość i nie zapisuje do listy overseera; odczyt/zapis złej lokalizacji nie tworzy ukrytej drugiej listy.
- Samo zakończenie implementacji nie zamyka taska zarządzającego, gdy pozostaje review, integracja lub inny wymagany krok.
- Błąd, brak wyniku lub anulowanie wymaganego poprzednika nie są traktowane jako udane spełnienie zależności.
- Zajęte worktree nie otrzymuje drugiego wykonawcy; nieznany stan nie oznacza wolnego zasobu ani pozwolenia na nadpisanie zmian.
- Powtórzony raport nie uruchamia następnego kroku dwa razy; raport niepasujący do zlecenia lub eskalacja nie są traktowane jako sukces.

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
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Wszystkie dzieci objęto review osobno. Pending oznacza gotową specyfikację, nie ukończoną funkcję ani zniesienie dependencies. Zlecenie tej grupy rozpoczyna się od dostępnych liści według execution-order.md; późniejsza blokada nie zatrzymuje wcześniejszego zakresu. Jeden główny zakres ma jedno worktree, role i subtaski pracują kolejno, a potrzebne poprzednikom fragmenty można integrować osobnymi PR-ami.

Źródła: `docs/lab-flow.md`, ADR-034 i review poszczególnych dzieci.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
