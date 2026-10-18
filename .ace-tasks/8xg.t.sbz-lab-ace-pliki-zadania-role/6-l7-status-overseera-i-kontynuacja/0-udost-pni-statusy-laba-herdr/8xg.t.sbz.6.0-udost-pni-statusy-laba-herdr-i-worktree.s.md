---
id: 8xg.t.sbz.6.0
status: done
priority: medium
created_at: "2026-10-17 18:54:22"
estimate: medium
dependencies: [8xg.t.sbz.0]
tags: [lab, lab-l7, file-based]
parent: 8xg.t.sbz.6
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-overseer/docs/usage.md, ace-herdr/README.md, ace-git-worktree/docs/usage.md, ace-handbook-integration-pi/handbook/extensions/ace-wake/index.js, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/0-ace-herdr-status-spaces-tabs/8xg.t.qn6.0-ace-herdr-status-spaces-tabs-and-panes.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/1-ace-lab-status-lab-configuration/8xg.t.qn6.1-ace-lab-status-lab-configuration-and-state.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md, .ace-tasks/_archive/8x/x/8xd.t.cm3-durable-goal-capability-for-pi/8xd.t.cm3-durable-goal-capability-for-pi-agents-objective.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/0-udost-pni-statusy-laba-herdr/ux/usage.md, .ace-tasks/8xg.t.k9y-ace-git-worktree-list-active/8xg.t.k9y-ace-git-worktree-list-active-worktree-table.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md, ace-herdr/lib/ace/herdr/cli/commands/list.rb]
  commands: []
title: Udostępnić statusy laba Herdr i worktree
---

# Udostępnić statusy laba Herdr i worktree

## Cel

Overseer widzi rzeczywistą sytuację i kontynuuje już zlecony proces po wiadomości lub restarcie. Ten subtask dostarcza następujący wycinek: Dostarczyć ace-herdr status pokazujący spaces/tabs/panes oraz ace-lab status czytający konfigurację i pliki. Widok worktree oprzeć na ukończonym k9y i obecnym ace-git-worktree list.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-overseer status, ace-lab status, ace-herdr status oraz istniejące ace-git-worktree list; konfiguracja źródeł i kontynuacja w pi.

Dostarczyć ace-herdr status pokazujący spaces/tabs/panes oraz ace-lab status czytający konfigurację i pliki. Widok worktree oprzeć na ukończonym k9y i obecnym ace-git-worktree list.

## Kryteria odbioru

- [x] Bez starego procesu właściciela laba widać konfigurację i lokalny stan; Herdr pokazuje rzeczywisty układ, a worktree zachowują skojarzenia z taskami.
- [x] Nieobecny runtime lub niepełna konfiguracja są oznaczone, a nie przedstawione jako pusty i gotowy lab. Nie dublować funkcji k9y.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Bez starego procesu właściciela laba widać konfigurację i lokalny stan; Herdr pokazuje rzeczywisty układ, a worktree zachowują skojarzenia z taskami.
- Scenariusz błędu / niepoprawnego wejścia: Nieobecny runtime lub niepełna konfiguracja są oznaczone, a nie przedstawione jako pusty i gotowy lab. Nie dublować funkcji k9y.
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
- [8xg.t.qn6.0](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/0-ace-herdr-status-spaces-tabs/8xg.t.qn6.0-ace-herdr-status-spaces-tabs-and-panes.s.md)
- [8xg.t.qn6.1](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/1-ace-lab-status-lab-configuration/8xg.t.qn6.1-ace-lab-status-lab-configuration-and-state.s.md)
- [8xg.t.qn6.4](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)
- [8xd.t.cm3](.ace-tasks/_archive/8x/x/8xd.t.cm3-durable-goal-capability-for-pi/8xd.t.cm3-durable-goal-capability-for-pi-agents-objective.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

Status worktree korzysta z ukończonego `8xg.t.k9y`; obecnym publicznym wejściem jest `ace-git-worktree list`. Nie tworzyć drugiej implementacji tylko dla nazwy status. L7.1 może być wykonany wcześniej niż cała rodzina L7.

## Review gotowości — 2026-10-18, po PR #379

`ace-herdr status` zestawia istniejące list_workspaces/list_tabs/list_panes w czytelny układ; `ace-lab status` czyta obecną konfigurację/topologię i dostępne pliki. Status nie uruchamia usług ani nie wymaga przyszłego instalatora. Widok worktree wykorzystuje istniejące `ace-git-worktree list` (k9y), bez nowej implementacji tej funkcji.
Odbiór: przygotowana konfiguracja + dostępny Herdr, niedostępny Herdr i brak konfiguracji laba. Wynik rozróżnia pusty poprawny zbiór, brak konfiguracji i błąd źródła. Brak coworkera/overseera jest informacją, nie blokadą budowy tego liścia. Nie deklarować ich gotowości na podstawie samej topologii.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-herdr/lib/ace/herdr/cli/commands/list.rb`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
