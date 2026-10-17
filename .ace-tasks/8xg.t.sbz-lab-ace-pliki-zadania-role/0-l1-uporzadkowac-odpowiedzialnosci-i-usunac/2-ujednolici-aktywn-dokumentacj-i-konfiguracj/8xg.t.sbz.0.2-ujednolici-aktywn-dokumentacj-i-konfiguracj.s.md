---
id: 8xg.t.sbz.0.2
status: done
priority: medium
created_at: "2026-10-17 18:54:10"
estimate: medium
dependencies: [8xg.t.sbz.0.1]
tags: [lab, lab-l1, file-based]
parent: 8xg.t.sbz.0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-lab/README.md, ace-assign/README.md, ace-overseer/README.md, ace-hitl/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/2-ujednolici-aktywn-dokumentacj-i-konfiguracj/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: Ujednolicić aktywną dokumentację i konfigurację
---

# Ujednolicić aktywną dokumentację i konfigurację

## Cel

Aktywne komendy, konfiguracja i instrukcje opisują jeden plikowy przepływ ACE. Ten subtask dostarcza następujący wycinek: Ujednolicić aktywne README, instrukcje, presety i konfigurację wokół przyjętych właścicieli stanu. Stare taski i raporty pozostają historycznym kontekstem.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Operacje istniejących ace-task i ace-assign działają lokalnie na ich plikach; nowe zachowanie nie wymaga starego authority.

Ujednolicić aktywne README, instrukcje, presety i konfigurację wokół przyjętych właścicieli stanu. Stare taski i raporty pozostają historycznym kontekstem.

## Kryteria odbioru

- [x] Świeża sesja czytająca aktywne instrukcje potrafi przejść plikowy przepływ bez dokumentacji starego laba.
- [x] Żadna aktywna instrukcja nowego przepływu nie odsyła do anulowanego taska jako obowiązującego właściciela ani nie wymaga starego journala.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Świeża sesja czytająca aktywne instrukcje potrafi przejść plikowy przepływ bez dokumentacji starego laba.
- Scenariusz błędu / niepoprawnego wejścia: Żadna aktywna instrukcja nowego przepływu nie odsyła do anulowanego taska jako obowiązującego właściciela ani nie wymaga starego journala.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L1.2 / 8xg.t.sbz.0.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/1-upro-ci-istniej-ce-cie/8xg.t.sbz.0.1-upro-ci-istniej-ce-cie-ki-wykonania.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Decyzje implementacyjne (przegląd gotowości)

- Jednym kanonicznym opisem przepływu jest `docs/lab-flow.md`; świeża sesja
  przechodzi lokalny przepływ task → plan → worktree → `ace-assign create` →
  `/as-assign-drive` → test/review → PR bez dokumentacji starego laba.
- Przepisać lub usunąć aktywne dokumenty: `ace-lab` README/usage/defaults
  (bez control-plane), `ace-overseer` README/usage/`overseer.wf`/role charters,
  `ace-hitl` README/usage (pliki zdarzeń; L2), `ace-assign` README/usage/
  `protected-authority`, `ace-herdr`/`ace-runtime`/`ace-hitl-hermes` sekcje
  protected, `ace-review`/`ace-git` PR/`perform-delivery` wymagania journala,
  `.ace-handbook/guides/project-delivery.g.md`, `.ace/README.md`,
  `docs/blueprint.md`, `docs/quick-start.md`.
- Zaznaczyć fale L2–L10 jako "planned — not available yet"; stare ID tasków
  występują tylko w `.ace-tasks/` (historia) i CHANGELOG.
- Naprawić `.ace/handbook/config.yml` (pi/delivery queue) oraz opis
  `scope-lab-runtime`; ujednolicić właścicieli w configach.
- Zsynchronizować `.agents/skills` po zmianach handbook (`ace-handbook sync`)
  i zweryfikować rozwiązywanie `wfi://` oraz `ace-handbook status`.
- Weryfikacja: `ace-lint`, `ace-docs validate --syntax`, `ace-nav resolve`,
  `ace-bundle project`, `ace-test ace-handbook all`, `ace-test-suite`.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.2](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md)
- [8xb.t.iy6](.ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
