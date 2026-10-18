---
id: 8xg.t.sbz.1.3
status: done
priority: medium
created_at: "2026-10-17 18:54:12"
estimate: medium
dependencies: [8xg.t.sbz.1.2]
tags: [lab, lab-l2, file-based]
parent: 8xg.t.sbz.1
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-hitl/README.md, ace-hitl/docs/usage.md, ace-hitl-hermes/README.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/3-zachowa-i-ponawia-niedostarczone-wiadomo/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md]
  commands: []
title: Zachować i ponawiać niedostarczone wiadomości
---

# Zachować i ponawiać niedostarczone wiadomości

## Cel

Nadawca komunikuje się z człowiekiem i agentem przez ten sam interfejs. Ten subtask dostarcza następujący wycinek: Niedostarczona wiadomość oraz powód błędu pozostają w lokalnych plikach HITL. Ponawia się dostarczenie tej samej sprawy, a nie jej zadanie.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Niedostarczona wiadomość oraz powód błędu pozostają w lokalnych plikach HITL. Ponawia się dostarczenie tej samej sprawy, a nie jej zadanie.

## Kryteria odbioru

- [x] Po przywróceniu transportu zachowany raport trafia do overseera z tym samym powiązaniem do taska.
- [x] Utrata potwierdzenia dostarczenia i ponowienie nie wykonują ponownie assignmentu ani nie odblokowują następnego kroku dwa razy.
- [x] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Po przywróceniu transportu zachowany raport trafia do overseera z tym samym powiązaniem do taska.
- Scenariusz błędu / niepoprawnego wejścia: Utrata potwierdzenia dostarczenia i ponowienie nie wykonują ponownie assignmentu ani nie odblokowują następnego kroku dwa razy.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L2.3 / 8xg.t.sbz.1.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/2-zachowa-wsp-lny-interfejs-i/8xg.t.sbz.1.2-zachowa-wsp-lny-interfejs-i-konfigurowalne-adaptery.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Gotowość specyfikacji i możliwość startu są odrębne: po review sprawdzić dependencies konkretnego liścia. Samo pending nie usuwa zależności.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Ponowienie zachowuje ID i treść lokalnego zdarzenia; użytkownik/agent ponawia dostarczenie, nie assignment. Przy częściowym sukcesie ponawiane są trasy niedostarczone lub o nieznanym wyniku. Przy nieznanym wyniku możliwy jest duplikat, więc odbiorca rozpoznaje ID; nie obiecujemy exactly-once transportu.
Test: odbiorca przyjął raport, potwierdzenie zaginęło, ponowienie niesie to samo ID. W tym liściu odbiorca testowy potwierdza identyfikowalność duplikatu; faktyczne nieuruchomienie kolejnego kroku drugi raz odbieramy w .5.4. Brak zależności implementacyjnej od przyszłego overseera.

Źródła: `docs/lab-flow.md`, ADR-034 i `ace-hitl-hermes/README.md`.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
