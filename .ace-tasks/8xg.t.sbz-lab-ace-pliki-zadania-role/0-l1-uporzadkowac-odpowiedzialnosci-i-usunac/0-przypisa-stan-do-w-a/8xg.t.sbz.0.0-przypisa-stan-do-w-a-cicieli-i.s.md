---
id: 8xg.t.sbz.0.0
status: done
priority: medium
created_at: "2026-10-17 18:54:09"
estimate: medium
dependencies: []
tags: [lab, lab-l1, file-based]
parent: 8xg.t.sbz.0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-lab/README.md, ace-assign/README.md, ace-overseer/README.md, ace-hitl/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/8xg.t.sbz.0-l1-uporzadkowac-odpowiedzialnosci-i-usunac-stary-model.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/0-l1-uporzadkowac-odpowiedzialnosci-i-usunac/0-przypisa-stan-do-w-a/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: Przypisać stan do właścicieli i lokalizacji
---

# Przypisać stan do właścicieli i lokalizacji

## Cel

Aktywne komendy, konfiguracja i instrukcje opisują jeden plikowy przepływ ACE. Ten subtask dostarcza następujący wycinek: Zadania projektowe, prywatne _overseer, assignmenty, konfiguracja coworkera i pliki HITL mają jawnego właściciela; każda informacja ma jedno miejsce zapisu.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Operacje istniejących ace-task i ace-assign działają lokalnie na ich plikach; nowe zachowanie nie wymaga starego authority.

Zadania projektowe, prywatne _overseer, assignmenty, konfiguracja coworkera i pliki HITL mają jawnego właściciela; każda informacja ma jedno miejsce zapisu.

## Kryteria odbioru

- [x] W przykładzie task → assignment → raport można wskazać plik i właściciela każdej zmiany; _overseer nie jest śledzony przez Git.
- [x] Coworker nie zapisuje do _overseer ani nie utrzymuje kopii kolejki; brak konfiguracji właściciela jest pokazany jako brak gotowości.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: W przykładzie task → assignment → raport można wskazać plik i właściciela każdej zmiany; _overseer nie jest śledzony przez Git.
- Scenariusz błędu / niepoprawnego wejścia: Coworker nie zapisuje do _overseer ani nie utrzymuje kopii kolejki; brak konfiguracji właściciela jest pokazany jako brak gotowości.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

Brak twardych poprzedników.

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Decyzje implementacyjne (przegląd gotowości)

- Prywatna lista `_overseer`: mapowanie magazynów w konfiguracji ace-task
  (`stores: {_overseer: .ace-local/overseer/tasks}`). `ace-task --in _overseer`
  rozwiązuje magazyn przed walidacją folderu; `create`, `list`, `show`, `update`
  (oraz `status`/`plan` w zakresie projektu) obsługują magazyn; skaner zadań
  projektowych go nie widzi. Magazyn jest nietrackowany, bo leży w `.ace-local/`.
- Kanoniczny dokument właścicieli `docs/lab-flow.md` (`doc-type: bundle`): jedno
  miejsce zapisu dla `.ace-tasks/` (ace-task), `.ace-local/overseer/tasks/`
  (prywatny `_overseer`), `.ace-local/assign/` (ace-assign),
  `.ace-local/coworker/` (zarezerwowane dla L3),
  `.ace-local/hitl/` (ace-hitl), `.ace-wt/` (jedno worktree na task projektowy).
  Jawne nie-właściciele: brak journala, authority/admission, listenera/daemona,
  rejestru topologii, silnika kolejki, brokera autoryzacji mutacji i dodatkowego
  cache'u stanu.
- `AGENTS.md`, `README.md`, `docs/quick-start.md` i
  `.ace/bundle/presets/project.md` linkują/włączają `docs/lab-flow.md`, aby świeża
  sesja miała właścicieli w kontekście projektu; ADR-034 zapisuje decyzję.
- README pakietów (ace-task, ace-assign, ace-overseer, ace-hitl) dostają jedną
  linię "State owner" wskazującą plik/magazyn i właściciela.
- Testy: ace-task — mapowanie magazynu, izolacja skanera projektu,
  `--in _overseer` dla create/show/update/list; naprawa sprzecznego
  `root_cli_test.rb` (obecnie twierdzi, że `_overseer` nie istnieje).
- Nie dodajemy usługi, journala, kolejki ani drugiego magazynu stanu.

Weryfikacja: `bin/ace-test ace-task all`; `bin/ace-bundle project` zawiera
`docs/lab-flow.md`.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.2](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md)
- [8xb.t.iy6](.ace-tasks/_archive/8x/x/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
