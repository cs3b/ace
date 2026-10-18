---
id: 8xg.t.sbz.1
status: done
priority: high
created_at: "2026-10-17 18:53:33"
estimate: large
dependencies: []
tags: [lab, lab-l2, file-based]
parent: 8xg.t.sbz
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-hitl/README.md, ace-hitl/docs/usage.md, ace-hitl-hermes/README.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md, docs/lab-flow.md, docs/decisions/ADR-034-file-based-lab-state-ownership.md]
  commands: []
title: "L2: Wspólna komunikacja przez ace-hitl i adaptery"
---

# L2: Wspólna komunikacja przez ace-hitl i adaptery

## Cel i zachowanie

Nadawca komunikuje się z człowiekiem i agentem przez ten sam interfejs.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Interfejs i rezultat

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

## Subtaski i kolejność

- [8xg.t.sbz.1.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/0-obs-u-y-raporty-oraz/8xg.t.sbz.1.0-obs-u-y-raporty-oraz-pro-by.s.md) — Ten sam interfejs ace-hitl obsługuje raport zakończenia/błędu oraz pytanie lub eskalację. Tylko prośba wymagająca decyzji oczekuje na odpowiedź.
- [8xg.t.sbz.1.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/1-ujednolici-adresowanie-odbiorc-w-i/8xg.t.sbz.1.1-ujednolici-adresowanie-odbiorc-w-i-reply.s.md) — Zachować adres odbiorcy: maszyna, folder i ID albo maszyna i panel. Odpowiedź wiąże się z pierwotną sprawą i właściwym agentem.
- [8xg.t.sbz.1.2](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/2-zachowa-wsp-lny-interfejs-i/8xg.t.sbz.1.2-zachowa-wsp-lny-interfejs-i-konfigurowalne-adaptery.s.md) — Wspólny interfejs nadawcy nie zależy od adaptera. Zachować ace-hitl-hermes jako adapter, istniejące drogi tmux/Herdr i konfigurację jednego lub kilku adapterów.
- [8xg.t.sbz.1.3](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/3-zachowa-i-ponawia-niedostarczone-wiadomo/8xg.t.sbz.1.3-zachowa-i-ponawia-niedostarczone-wiadomo-ci.s.md) — Niedostarczona wiadomość oraz powód błędu pozostają w lokalnych plikach HITL. Ponawia się dostarczenie tej samej sprawy, a nie jej zadanie.

## Kryteria odbioru

- [ ] Raport work done trafia do overseera bez oczekiwania na Reply; pytanie pozostaje oczekujące i może wstrzymać assignment.
- [ ] Dwa worktree z różnymi pytaniami otrzymują swoje Reply; raport można powiązać z właściwym taskiem i assignmentem.
- [ ] Przełączenie konfiguracji transportu nie wymaga zmiany assignmentu lub logiki coworkera; skonfigurowany zestaw tras raportuje własne wyniki dostarczenia.
- [ ] Po przywróceniu transportu zachowany raport trafia do overseera z tym samym powiązaniem do taska.

## Weryfikacja i scenariusze błędów

- Brak odpowiedzi na pytanie nie jest zgodą ani sukcesem; raport bez odpowiedzi nie staje się zablokowanym pytaniem.
- Nieznany odbiorca lub niepasujące ID daje jawny błąd i nie zapisuje odpowiedzi w cudzym zadaniu.
- Niedostępny adapter nie powoduje cichego wysłania do innego odbiorcy; dodanie przyszłego adaptera Nervus nie wymaga nowego interfejsu HITL.
- Utrata potwierdzenia dostarczenia i ponowienie nie wykonują ponownie assignmentu ani nie odblokowują następnego kroku dwa razy.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

To grupa odbioru. Start konkretnych prac określają dependencies jej liści; puste dependencies rodzica nie odblokowują wszystkich dzieci. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Gotowość specyfikacji i możliwość startu są odrębne: po review sprawdzić dependencies konkretnego liścia. Samo pending nie usuwa zależności.
Rozmiar orientacyjny: large. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Review gotowości — 2026-10-18, po PR #379

Wszystkie dzieci objęto review osobno. Pending oznacza gotową specyfikację, nie ukończoną funkcję ani zniesienie dependencies. Zlecenie tej grupy rozpoczyna się od dostępnych liści według execution-order.md; późniejsza blokada nie zatrzymuje wcześniejszego zakresu. Jeden główny zakres ma jedno worktree, role i subtaski pracują kolejno, a potrzebne poprzednikom fragmenty można integrować osobnymi PR-ami.

Źródła: `docs/lab-flow.md`, ADR-034 i review poszczególnych dzieci.
Weryfikacja implementacji: powyższe scenariusze pozytywne i błędne, testy zmienionych pakietów i niezależny review. Ten przegląd specyfikacji nie jest odbiorem implementacji.
