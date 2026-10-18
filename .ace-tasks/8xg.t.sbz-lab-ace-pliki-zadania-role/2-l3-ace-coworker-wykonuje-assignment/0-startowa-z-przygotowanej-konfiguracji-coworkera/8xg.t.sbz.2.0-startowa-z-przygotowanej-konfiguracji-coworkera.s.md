---
id: 8xg.t.sbz.2.0
status: done
priority: medium
created_at: "2026-10-17 18:54:12"
estimate: medium
dependencies: [8xg.t.sbz.0]
tags: [lab, lab-l3, file-based]
parent: 8xg.t.sbz.2
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-assign/README.md, ace-assign/docs/usage.md, ace-overseer/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/8xg.t.sbz.2-l3-ace-coworker-wykonuje-assignment-do-konca.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/2-ace-lab-one-shot-mutations/8xg.t.qn6.2-ace-lab-one-shot-mutations-assignment-operations.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/4-ace-coworker-gem-worker-loop/8xg.t.qn6.4-ace-coworker-gem-worker-loop-that-takes.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/2-l3-ace-coworker-wykonuje-assignment/0-startowa-z-przygotowanej-konfiguracji-coworkera/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md, ace-assign/handbook/workflow-instructions/assign/drive.wf.md]
  commands: []
title: Startować z przygotowanej konfiguracji coworkera
---

# Startować z przygotowanej konfiguracji coworkera

## Cel

Przygotowany wykonawca prowadzi własny assignment i zachowuje postęp. Ten subtask dostarcza następujący wycinek: Start coworkera czyta .ace-local/coworker/: rolę, źródło instrukcji, prompt startowy, task, istniejący assignment, adres overseera oraz zasady błędów.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

Wejście: .ace-local/coworker/ i wskazany ace-assign. Wyjście: wykonany assignment lub zapisany błąd oraz raport ace-hitl.

Start coworkera czyta .ace-local/coworker/: rolę, źródło instrukcji, prompt startowy, task, istniejący assignment, adres overseera oraz zasady błędów.

## Kryteria odbioru

- [x] Wykonawca startuje w przygotowanym worktree z właściwą rolą i dokładnie wskazanym assignmentem.
- [x] Brak instrukcji roli, taska albo assignmentu daje konkretny błąd; coworker nie zgaduje innego zlecenia.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Wykonawca startuje w przygotowanym worktree z właściwą rolą i dokładnie wskazanym assignmentem.
- Scenariusz błędu / niepoprawnego wejścia: Brak instrukcji roli, taska albo assignmentu daje konkretny błąd; coworker nie zgaduje innego zlecenia.
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

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Start w przygotowanym worktree odczytuje `.ace-local/coworker/`: rolę, źródło instrukcji, prompt, task, istniejący assignment, adres raportowania i instrukcję błędów. Rozwiązuje odwołania względem tego worktree i pokazuje wybrane task/assignment/rolę. Brak pliku lub niepasujące zlecenie kończy start błędem, bez tworzenia zastępczego assignmentu/worktree.
Odbiór tego liścia: walidacja kontekstu i przekazanie go wykonawcy, z lokalnym opisem błędu. Wysyłka HITL należy do .2.2. Fixture może zawierać prostą instrukcję roli i assignment utworzony istniejącym ace-assign; nie czeka na gotowe role .4 ani plannera .3. Ten task jest właścicielem udokumentowanego formatu startowego konsumowanego później przez plannera; nie dodawać kopii kroków assignmentu.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
