---
id: 8xg.t.sbz.0.1
status: done
priority: medium
created_at: "2026-10-17 18:54:09"
estimate: medium
dependencies: [8xg.t.sbz.0.0]
tags: [lab, lab-l1, file-based]
parent: 8xg.t.sbz.0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-lab/README.md, ace-assign/README.md, ace-overseer/README.md, ace-hitl/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/1-upro-ci-istniej-ce-cie/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: Uprościć istniejące ścieżki wykonania laba
---

# Uprościć istniejące ścieżki wykonania laba

## Cel

Aktywne komendy, konfiguracja i instrukcje opisują jeden plikowy przepływ ACE. Ten subtask dostarcza następujący wycinek: Zastąpić stare labowe authority/listenery/journale bezpośrednią pracą na istniejących plikach narzędzi. Usunąć wymagania protected execution w zastępowanym przepływie, zachowując potrzebne operacje.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Operacje istniejących ace-task i ace-assign działają lokalnie na ich plikach; nowe zachowanie nie wymaga starego authority.

Zastąpić stare labowe authority/listenery/journale bezpośrednią pracą na istniejących plikach narzędzi. Usunąć wymagania protected execution w zastępowanym przepływie, zachowując potrzebne operacje.

## Kryteria odbioru

- [x] Task i assignment można utworzyć, odczytać i prowadzić bez uruchamiania starej usługi admission i właściciela journala.
- [x] Brak starego listenera nie blokuje zwykłej pracy; rzeczywisty brak uprawnień do własnych plików jest zgłaszany. Nie usuwać transportu tmux/Herdr lub HITL tylko dlatego, że korzysta z socketu.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Task i assignment można utworzyć, odczytać i prowadzić bez uruchamiania starej usługi admission i właściciela journala.
- Scenariusz błędu / niepoprawnego wejścia: Brak starego listenera nie blokuje zwykłej pracy; rzeczywisty brak uprawnień do własnych plików jest zgłaszany. Nie usuwać transportu tmux/Herdr lub HITL tylko dlatego, że korzysta z socketu.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L1.1 / 8xg.t.sbz.0.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/0-przypisa-stan-do-w-a/8xg.t.sbz.0.0-przypisa-stan-do-w-a-cicieli-i.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Decyzje implementacyjne (przegląd gotowości)

- Usunąć z `ace-lab` protected authority/receiver/listener/worker/client/
  recovery/publication/cleanup stack (~3.3k linii) oraz generyczny
  admission/journal usług (`service request/status` bez `--mode`,
  `ServiceRequestService`/`ServicePolicy`/`ServiceExecutor`/`ServiceInput`/
  `ServiceReceipt`) wraz z testami protected/generic.
- Zachować potrzebne operacje: ordinary merge producer/receiver
  (`--mode ordinary-merge`), topology (L7), `ace-lab run` kernel, release
  staging/publisher, Forgejo adapter/config, HITL authorizer, grant/caller
  authorizers oraz transport listen socket.
- Usunąć protected tryby `ace-overseer`: protected work-on
  (`--project/--agent/--mutation/--recover-request`), protected status/review/
  stop/prompt/prune, `protected_selection`/`protected_steering`/
  `launch_request`/`original_launch_child`; zachować lokalne work-on/status/prune
  oraz ordinary path dla L3/L6.
- Usunąć protected-only testy `ace-assign` (`service_settlement`) i `ace-git`
  (`service_merge_boundary` + fixture); naprawić wiszący `require` w
  `ordinary_merge_request`.
- Wyłączyć stare wymagania z aktywnych instrukcji: `assign/drive` (gałąź
  ordinary installed + protected merge), `git/pr/create|update` (protected
  worker), `review/pr` (kampania), `perform-delivery` (protected/managed),
  `overseer.wf` (protected); usunąć protected/queue presety oraz
  `protected-authority.md`; zneutralizować `auto-merge`/`mark-pr-ready` do
  lokalnego review.
- Nie usuwać transportu tmux/Herdr/HITL; brak starego listenera nie blokuje
  lokalnej pracy, a rzeczywisty brak uprawnień do własnych plików jest zgłaszany.

Weryfikacja: `bin/ace-test ace-lab all`, `ace-overseer all`, `ace-assign all`,
`ace-git all`, `bin/ace-test-suite`.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.2](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md)
- [8xb.t.iy6](.ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
