---
id: 8xg.t.sbz.5.4
status: pending
priority: medium
created_at: "2026-10-17 18:54:21"
estimate: medium
dependencies: [8xg.t.sbz.5.3]
tags: [lab, lab-l6, file-based]
parent: 8xg.t.sbz.5
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-task/docs/usage.md, ace-overseer/README.md, ace-overseer/docs/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/4-przetwarza-raporty-i-kontynuowa-kolejk/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md, ace-hitl/README.md]
  commands: []
title: Przetwarzać raporty i kontynuować kolejkę
---

# Przetwarzać raporty i kontynuować kolejkę

## Cel

Drzewo _overseer określa kolejność, zależności i przydziały bez drugiego silnika kolejki. Ten subtask dostarcza następujący wycinek: Powiązać raport z właściwym taskiem i krokiem, zapisać go w prywatnym zadaniu zarządzającym, następnie uruchomić kolejny odblokowany krok lub obsłużyć błąd.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Prywatny ace-task --in _overseer, istniejące subtaski/dependencies oraz raporty ace-hitl powiązane z konkretnym krokiem.

Powiązać raport z właściwym taskiem i krokiem, zapisać go w prywatnym zadaniu zarządzającym, następnie uruchomić kolejny odblokowany krok lub obsłużyć błąd.

## Kryteria odbioru

- [ ] Jeden realny obieg planner → worker → raport → reviewer działa już w L6; wyniki aktualizują właściwy task nadrzędny.
- [ ] Powtórzony raport nie uruchamia następnego kroku dwa razy; raport niepasujący do zlecenia lub eskalacja nie są traktowane jako sukces.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Jeden realny obieg planner → worker → raport → reviewer działa już w L6; wyniki aktualizują właściwy task nadrzędny.
- Scenariusz błędu / niepoprawnego wejścia: Powtórzony raport nie uruchamia następnego kroku dwa razy; raport niepasujący do zlecenia lub eskalacja nie są traktowane jako sukces.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L6.4 / 8xg.t.sbz.5.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/3-przekazywa-worktree-kolejnym-wykonawcom/8xg.t.sbz.5.3-przekazywa-worktree-kolejnym-wykonawcom.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Gotowość specyfikacji i możliwość startu są odrębne: po review sprawdzić dependencies konkretnego liścia. Samo pending nie usuwa zależności.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.2](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Odbiorca dopasowuje ID wiadomości i referencje task/assignment/krok do bieżącego zlecenia. Wynik i ID przetworzonego raportu zapisuje w istniejącym tasku zarządzającym. Powtórzenie raportu sprawdza zapisany wynik i istniejący przydział zamiast ponownie uruchamiać rolę.
Niepasujący raport lub błąd pozostaje do wyjaśnienia, nie zamyka kroku sukcesem. Test rzeczywistego obiegu i przerwania między zapisem wyniku a następnym przydziałem; po wznowieniu odczytać zadanie i stan worktree. Bez osobnej tabeli deduplikacji/journala. Automatyczne budzenie pi należy do .6.2, nie jest warunkiem odbioru obiegu z dostarczonym raportem w .5.4.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-hitl/README.md`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
