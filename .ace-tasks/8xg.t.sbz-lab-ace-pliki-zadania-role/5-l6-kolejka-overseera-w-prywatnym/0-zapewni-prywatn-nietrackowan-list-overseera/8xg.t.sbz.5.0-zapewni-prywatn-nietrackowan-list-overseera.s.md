---
id: 8xg.t.sbz.5.0
status: pending
priority: medium
created_at: "2026-10-17 18:54:19"
estimate: medium
dependencies: [8xg.t.sbz.0]
tags: [lab, lab-l6, file-based]
parent: 8xg.t.sbz.5
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-task/docs/usage.md, ace-overseer/README.md, ace-overseer/docs/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/0-zapewni-prywatn-nietrackowan-list-overseera/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md]
  commands: []
title: Zapewnić prywatną nietrackowaną listę overseera
---

# Zapewnić prywatną nietrackowaną listę overseera

## Cel

Drzewo _overseer określa kolejność, zależności i przydziały bez drugiego silnika kolejki. Ten subtask dostarcza następujący wycinek: Zapewnić lokalną listę ace-task --in _overseer zarządzaną wyłącznie przez jej overseera, poza Git i odrębną od tasków projektowych.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Prywatny ace-task --in _overseer, istniejące subtaski/dependencies oraz raporty ace-hitl powiązane z konkretnym krokiem.

Zapewnić lokalną listę ace-task --in _overseer zarządzaną wyłącznie przez jej overseera, poza Git i odrębną od tasków projektowych.

## Kryteria odbioru

- [x] Po zapisie i wznowieniu lista jest dostępna dla właściciela; git status nie pokazuje jej jako plików do commitu.
- [x] Coworker raportuje przez wiadomość i nie zapisuje do listy overseera; odczyt/zapis złej lokalizacji nie tworzy ukrytej drugiej listy.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Po zapisie i wznowieniu lista jest dostępna dla właściciela; git status nie pokazuje jej jako plików do commitu.
- Scenariusz błędu / niepoprawnego wejścia: Coworker raportuje przez wiadomość i nie zapisuje do listy overseera; odczyt/zapis złej lokalizacji nie tworzy ukrytej drugiej listy.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L1 / 8xg.t.sbz.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md)

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

PR #379 już dostarczył zwykłą ignorowaną `.ace-tasks/_overseer/` i ogólne zachowanie ace-task. Pozostały zakres tego liścia to przygotowanie/udokumentowanie użycia przez rolę overseera i weryfikacja tego przepływu, nie nowe funkcje ace-task. Utworzenie folderu i wpisu Gitignore odbywa się w konfiguracji projektu; docelowy instalator konsumuje to w .7.
Użyć `ace-task create ... --in _overseer`, show/update/list i ponownego odczytu po wznowieniu. Wykazać Gitignore i brak zmian trackowanych. Reguła „coworker nie zapisuje listy” jest instrukcją roli; nie dodawać blokad nazw/ścieżek do ace-task, ace-assign ani ace-git-worktree. Subagenci mogą analizować i weryfikować plan; overseer pozostaje właścicielem jego zapisu. Brak HITL/coworkera nie blokuje lokalnego odbioru tego liścia.

Źródła: `docs/lab-flow.md`, ADR-034 i `docs/lab-flow.md`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
