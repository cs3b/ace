---
id: 8xs.t.pu0.b
status: draft
priority: medium
created_at: "2026-10-29 17:13:45"
estimate: medium
dependencies: [8xs.t.pu0.a]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-coworker/docs/usage.md", "ace-hitl/docs/usage.md", "ace-hitl-hermes/docs/usage.md", "ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/a-uruchamia-projekty-z-katalogu-laba/8xs.t.pu0.a-uruchamia-projekty-z-katalogu-laba.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/b-proponowa-odpowiedzi-jako-second-captain/ux/usage.md"], "commands": []}
---

# Proponować odpowiedzi jako Second Captain

## Cel

Odciążyć Kapitana przez widoczną propozycję odpowiedzi w tej samej sprawie HITL.

## Specyfikacja zachowania

Krok 12/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: medium.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- Second Captain jest skonfigurowaną rolą coworkera doradczego, delegowaną przez nadzorcę.
- Pytanie do człowieka otrzymuje propozycję odpowiedzi z krótkim uzasadnieniem i podstawami, oznaczoną jako sugestia w tym samym wątku.
- Wysłanie pytania nie czeka na dostępność doradcy. Agent nie odpowiada w imieniu człowieka i nie zatwierdza działania.
- Jeśli człowiek odpowie przed sugestią, jego decyzja pozostaje obowiązująca; późna sugestia nie otwiera sprawy ani nie zastępuje odpowiedzi.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Sugestia przed decyzją | Nadzorca kieruje pytanie do Kapitana i rolę doradczą do Second Captaina | W tej samej sprawie pojawia się oznaczona propozycja z uzasadnieniem. |
| Brak doradcy | Wyłączyć dostępność coworkera doradczego i zadać pytanie | Pytanie dociera do Kapitana bez oczekiwania na sugestię. |
| Człowiek szybszy niż agent | Kapitan odpowiada przed zakończeniem pracy doradcy | Decyzja człowieka pozostaje obowiązująca; brak drugiego zatwierdzenia. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Kapitan odróżnia pytanie, sugestię i swoją decyzję w jednym wątku.
- [ ] Niedostępny doradca nie opóźnia dostawy pytania do człowieka.
- [ ] Sugestia nigdy nie zwalnia operacji wymagającej ludzkiej decyzji.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-coworker
- bin/ace-test ace-hitl
- bin/ace-test ace-hitl-hermes
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.a.
Następny krok: 8xs.t.pu0.c.
Starsze zakresy do wykorzystania: 8xg.t.sbz.1, 8xg.t.sbz.4.

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
- ace-coworker/docs/usage.md
- ace-hitl/docs/usage.md
- ace-hitl-hermes/docs/usage.md
- ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/a-uruchamia-projekty-z-katalogu-laba/8xs.t.pu0.a-uruchamia-projekty-z-katalogu-laba.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/b-proponowa-odpowiedzi-jako-second-captain/ux/usage.md
