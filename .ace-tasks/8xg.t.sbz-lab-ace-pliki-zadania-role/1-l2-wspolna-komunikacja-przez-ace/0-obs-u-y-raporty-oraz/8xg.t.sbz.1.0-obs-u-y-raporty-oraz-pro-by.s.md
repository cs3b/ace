---
id: 8xg.t.sbz.1.0
status: in-progress
priority: medium
created_at: "2026-10-17 18:54:10"
estimate: medium
dependencies: [8xg.t.sbz.0]
tags: [lab, lab-l2, file-based]
parent: 8xg.t.sbz.1
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-hitl/README.md, ace-hitl/docs/usage.md, ace-hitl-hermes/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/0-obs-u-y-raporty-oraz/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md, ace-hitl/lib/ace/hitl/cli/commands/create.rb]
  commands: []
title: Obsłużyć raporty oraz prośby o odpowiedź
---

# Obsłużyć raporty oraz prośby o odpowiedź

## Cel

Nadawca komunikuje się z człowiekiem i agentem przez ten sam interfejs. Ten subtask dostarcza następujący wycinek: Ten sam interfejs ace-hitl obsługuje raport zakończenia/błędu oraz pytanie lub eskalację. Tylko prośba wymagająca decyzji oczekuje na odpowiedź.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Ten sam interfejs ace-hitl obsługuje raport zakończenia/błędu oraz pytanie lub eskalację. Tylko prośba wymagająca decyzji oczekuje na odpowiedź.

## Kryteria odbioru

- [x] Raport work done trafia do overseera bez oczekiwania na Reply; pytanie pozostaje oczekujące i może wstrzymać assignment.
- [x] Brak odpowiedzi na pytanie nie jest zgodą ani sukcesem; raport bez odpowiedzi nie staje się zablokowanym pytaniem.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Raport work done trafia do overseera bez oczekiwania na Reply; pytanie pozostaje oczekujące i może wstrzymać assignment.
- Scenariusz błędu / niepoprawnego wejścia: Brak odpowiedzi na pytanie nie jest zgodą ani sukcesem; raport bez odpowiedzi nie staje się zablokowanym pytaniem.
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

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Rozszerzyć istniejący plikowy interfejs `ace-hitl create/show/update/wait`, zamiast odtwarzać usunięte `overseer-send`. Rozróżnienie raportu od pytania należy do zdarzenia HITL, nie do roli odbiorcy. Raport zawiera wynik (sukces/błąd), treść i referencje task/assignment/krok, ma własne ID i nie oczekuje odpowiedzi. Pytanie zachowuje istniejący cykl odpowiedzi. Zapis lokalny nie oznacza dostarczenia.
Pierwszy wycinek odbieramy lokalnie: utworzenie raportu, odczyt i brak oczekiwania na odpowiedź; pytanie pozostaje oczekujące. Zdalne adresowanie i adaptery są kolejnymi liśćmi .1.1–.1.3, nie warunkiem rozpoczęcia .1.0. Publiczną składnię rozszerzenia utrwalić w help/usage przed integracją konsumentów.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-hitl/lib/ace/hitl/cli/commands/create.rb`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
