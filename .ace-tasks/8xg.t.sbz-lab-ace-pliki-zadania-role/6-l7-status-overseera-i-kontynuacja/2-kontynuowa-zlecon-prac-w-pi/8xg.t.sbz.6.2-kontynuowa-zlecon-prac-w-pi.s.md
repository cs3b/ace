---
id: 8xg.t.sbz.6.2
status: draft
priority: medium
created_at: "2026-10-17 18:54:23"
estimate: medium
dependencies: ["8xg.t.sbz.5", "8xg.t.sbz.1"]
tags: ["lab", "lab-l7", "file-based"]
parent: 8xg.t.sbz.6
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-overseer/docs/usage.md", "ace-herdr/README.md", "ace-git-worktree/docs/usage.md", "ace-handbook-integration-pi/handbook/extensions/ace-wake/index.js", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/0-ace-herdr-status-spaces-tabs/8xg.t.qn6.0-ace-herdr-status-spaces-tabs-and-panes.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/1-ace-lab-status-lab-configuration/8xg.t.qn6.1-ace-lab-status-lab-configuration-and-state.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md", ".ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md", ".ace-tasks/_archive/8x/x/8xd.t.cm3-durable-goal-capability-for-pi/8xd.t.cm3-durable-goal-capability-for-pi-agents-objective.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/2-kontynuowa-zlecon-prac-w-pi/ux/usage.md", ".ace-tasks/8xg.t.k9y-ace-git-worktree-list-active/8xg.t.k9y-ace-git-worktree-list-active-worktree-table.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Kontynuować zleconą pracę w pi"
---

# Kontynuować zleconą pracę w pi

## Cel

Overseer widzi rzeczywistą sytuację i kontynuuje już zlecony proces po wiadomości lub restarcie. Ten subtask dostarcza następujący wycinek: Mechanizmy w pi przyjmują wiadomości podczas pracy i oczekiwania oraz wznawiają zlecony proces. Po restarcie overseer czyta _overseer i aktualną prawdę o projekcie.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-overseer status, ace-lab status, ace-herdr status oraz istniejące ace-git-worktree list; konfiguracja źródeł i kontynuacja w pi.

Mechanizmy w pi przyjmują wiadomości podczas pracy i oczekiwania oraz wznawiają zlecony proces. Po restarcie overseer czyta _overseer i aktualną prawdę o projekcie.

## Kryteria odbioru

- [ ] Raport budzi oczekującego overseera; po restarcie kontynuuje on ten sam proces i istniejące assignmenty.
- [ ] Powtórzone powiadomienia nie tworzą drugiej egzekucji; brak nowej zleconej pracy nie prowadzi do samodzielnego szukania kolejnych zadań.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Raport budzi oczekującego overseera; po restarcie kontynuuje on ten sam proces i istniejące assignmenty.
- Scenariusz błędu / niepoprawnego wejścia: Powtórzone powiadomienia nie tworzą drugiej egzekucji; brak nowej zleconej pracy nie prowadzi do samodzielnego szukania kolejnych zadań.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L6 / 8xg.t.sbz.5](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md), [L2 / 8xg.t.sbz.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.0](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/0-ace-herdr-status-spaces-tabs/8xg.t.qn6.0-ace-herdr-status-spaces-tabs-and-panes.s.md)
- [8xg.t.qn6.1](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/1-ace-lab-status-lab-configuration/8xg.t.qn6.1-ace-lab-status-lab-configuration-and-state.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)
- [8xd.t.cm3](.ace-tasks/_archive/8x/x/8xd.t.cm3-durable-goal-capability-for-pi/8xd.t.cm3-durable-goal-capability-for-pi-agents-objective.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Status worktree korzysta z ukończonego `8xg.t.k9y`; obecnym publicznym wejściem jest `ace-git-worktree list`. Nie tworzyć drugiej implementacji tylko dla nazwy status. L7.1 może być wykonany wcześniej niż cała rodzina L7.
