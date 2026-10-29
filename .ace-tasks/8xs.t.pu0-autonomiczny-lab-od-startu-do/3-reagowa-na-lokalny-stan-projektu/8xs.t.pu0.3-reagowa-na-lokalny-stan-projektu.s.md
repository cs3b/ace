---
id: 8xs.t.pu0.3
status: draft
priority: medium
created_at: "2026-10-29 17:13:42"
estimate: large
dependencies: [8xs.t.pu0.2]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-overseer/docs/usage.md", "ace-hitl/docs/usage.md", "ace-coworker/docs/usage.md", "ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md", "ace-handbook-integration-pi/handbook/extensions/ace-wake/wake/eyes.js", "ace-handbook-integration-pi/handbook/extensions/ace-wake/wake/eyes-runtime.js", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/2-uruchamia-obserwatory-zmian-przez-watch/8xs.t.pu0.2-uruchamia-obserwatory-zmian-przez-watch.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/3-reagowa-na-lokalny-stan-projektu/ux/usage.md"], "commands": []}
---

# Reagować na lokalny stan projektu

## Cel

Sprawić, żeby nadzorca projektu sam zauważał zmianę i kontynuował pracę, także po restarcie.

## Specyfikacja zachowania

Krok 04/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- Start uzbraja obserwację zadań, dostępnego zespołu, worktree, postępu assignmentów i raportów HITL.
- Po wybudzeniu nadzorca odczytuje stan od właścicieli, interpretuje raport i wybiera dozwolony następny krok. Nie tworzy osobnej kolejki.
- Restart odtwarza obserwację oraz rozpoznaje nieobsłużone zmiany powstałe podczas nieobecności.
- Zdrowa cisza nie zużywa tur modelu; utrata obserwacji jest wykazywana jako brak danych/awaria.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Raport końca pracy | Coworker raportuje wynik; nadzorca obserwuje projekt | Nadzorca przetwarza raport i wybiera kolejny etap zgodny z zależnościami. |
| Restart | Zatrzymać nadzorcę, dostarczyć raport, uruchomić ace-overseer start | Oczekujący raport zostaje obsłużony bez zgubienia lub zdublowania pracy. |
| Cisza i awaria | Pozostawić stan bez zmian, następnie odłączyć źródło | Cisza nie uruchamia modelu; awaria jest odróżniona od zdrowego braku zmian. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Raport coworkera zmienia widoczny stan i wywołuje odpowiednią kontynuację bez ręcznego promptu.
- [ ] Raport zapisany podczas przerwy zostaje rozpoznany po starcie.
- [ ] Powtórzona obserwacja obsłużonego raportu nie powtarza wykonanego kroku.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-overseer
- bin/ace-test ace-handbook-integration-pi
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.2.
Następny krok: 8xs.t.pu0.4.
Starsze zakresy do wykorzystania: 8xg.t.sbz.5, 8xg.t.sbz.6.

## Decyzje i granice

Zachowanie wynika z zaakceptowanego briefu. Szczegóły techniczne wymagają review aktualnych źródeł przed wykonaniem. Brak nowych pytań produktowych blokujących zapis draftu.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-overseer/docs/usage.md
- ace-hitl/docs/usage.md
- ace-coworker/docs/usage.md
- ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md
- ace-handbook-integration-pi/handbook/extensions/ace-wake/wake/eyes.js
- ace-handbook-integration-pi/handbook/extensions/ace-wake/wake/eyes-runtime.js
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/2-uruchamia-obserwatory-zmian-przez-watch/8xs.t.pu0.2-uruchamia-obserwatory-zmian-przez-watch.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/3-reagowa-na-lokalny-stan-projektu/ux/usage.md
