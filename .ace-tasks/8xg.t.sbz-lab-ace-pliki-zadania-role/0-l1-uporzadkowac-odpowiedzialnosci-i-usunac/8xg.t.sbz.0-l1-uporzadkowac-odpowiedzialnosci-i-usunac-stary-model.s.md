---
id: 8xg.t.sbz.0
status: done
priority: critical
created_at: "2026-10-17 18:53:33"
estimate: large
dependencies: []
tags: [lab, lab-l1, file-based]
parent: 8xg.t.sbz
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-lab/README.md, ace-assign/README.md, ace-overseer/README.md, ace-hitl/README.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: "L1: Uporządkować odpowiedzialności i usunąć stary model laba"
---

# L1: Uporządkować odpowiedzialności i usunąć stary model laba

## Cel i zachowanie

Aktywne komendy, konfiguracja i instrukcje opisują jeden plikowy przepływ ACE.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

Operacje istniejących ace-task i ace-assign działają lokalnie na ich plikach; nowe zachowanie nie wymaga starego authority.

## Subtaski i kolejność

- [8xg.t.sbz.0.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/0-przypisa-stan-do-w-a/8xg.t.sbz.0.0-przypisa-stan-do-w-a-cicieli-i.s.md) — Zadania projektowe, prywatne _overseer, assignmenty, konfiguracja coworkera i pliki HITL mają jawnego właściciela; każda informacja ma jedno miejsce zapisu.
- [8xg.t.sbz.0.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/1-upro-ci-istniej-ce-cie/8xg.t.sbz.0.1-upro-ci-istniej-ce-cie-ki-wykonania.s.md) — Zastąpić stare labowe authority/listenery/journale bezpośrednią pracą na istniejących plikach narzędzi. Usunąć wymagania protected execution w zastępowanym przepływie, zachowując potrzebne operacje.
- [8xg.t.sbz.0.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/2-ujednolici-aktywn-dokumentacj-i-konfiguracj/8xg.t.sbz.0.2-ujednolici-aktywn-dokumentacj-i-konfiguracj.s.md) — Ujednolicić aktywne README, instrukcje, presety i konfigurację wokół przyjętych właścicieli stanu. Stare taski i raporty pozostają historycznym kontekstem.

## Kryteria odbioru

- [x] W przykładzie task → assignment → raport można wskazać plik i właściciela każdej zmiany; _overseer nie jest śledzony przez Git.
- [x] Task i assignment można utworzyć, odczytać i prowadzić bez uruchamiania starej usługi admission i właściciela journala.
- [x] Świeża sesja czytająca aktywne instrukcje potrafi przejść plikowy przepływ bez dokumentacji starego laba.

## Weryfikacja i scenariusze błędów

- Coworker nie zapisuje do _overseer ani nie utrzymuje kopii kolejki; brak konfiguracji właściciela jest pokazany jako brak gotowości.
- Brak starego listenera nie blokuje zwykłej pracy; rzeczywisty brak uprawnień do własnych plików jest zgłaszany. Nie usuwać transportu tmux/Herdr lub HITL tylko dlatego, że korzysta z socketu.
- Żadna aktywna instrukcja nowego przepływu nie odsyła do anulowanego taska jako obowiązującego właściciela ani nie wymaga starego journala.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

To grupa odbioru. Start konkretnych prac określają dependencies jej liści; puste dependencies rodzica nie odblokowują wszystkich dzieci. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: large. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.2](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md)
- [8xb.t.iy6](.ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
