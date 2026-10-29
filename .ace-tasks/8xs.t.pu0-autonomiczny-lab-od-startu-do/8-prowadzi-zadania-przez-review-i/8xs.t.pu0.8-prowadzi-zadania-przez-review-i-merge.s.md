---
id: 8xs.t.pu0.8
status: draft
priority: medium
created_at: "2026-10-29 17:13:44"
estimate: large
dependencies: [8xs.t.pu0.7]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-coworker/docs/usage.md", "ace-overseer/docs/usage.md", "ace-git/docs/usage.md", "ace-coworker/handbook/workflow-instructions/coworker/reviewer.wf.md", "ace-coworker/handbook/workflow-instructions/coworker/integrator.wf.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/ux/usage.md"], "commands": []}
---

# Prowadzić zadania przez review i merge

## Cel

Połączyć wykonanie, testy, niezależny review i merge w automatycznie kontynuowany odcinek.

## Specyfikacja zachowania

Krok 09/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- Raport workera uruchamia właściwe przekazanie do reviewera i dalszej integracji przez istniejące assignmenty.
- Wynik testów i niezależny review odnoszą się do konkretnego HEAD. Obowiązują istniejące reguły rund review i gate.
- Formalny approver jest właściwym kontem lane; formalny status nie zastępuje niezależnego review.
- Zmiana kandydata wymaga aktualizacji podstaw integracji. CI pozostaje advisory zgodnie z decyzją Kapitana.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Poprawny kandydat | Worker dostarcza PR, reviewer sprawdza go, integrator odbiera | Wykonane testy i niezależny werdykt wraz z wymaganym approval prowadzą do merge. |
| Zmiana HEAD | Zmienić kandydata po review przed merge | Następuje właściwa ponowna weryfikacja nowego kandydata. |
| Brak dowodu | Zgłosić sukces bez wykonanych testów lub z nierozwiązanym wymaganym findingiem | Gate zatrzymuje integrację i pokazuje brakującą podstawę. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Jedno zlecenie przechodzi worker → reviewer → integracja bez ręcznego przenoszenia promptów.
- [ ] Brak wykonanych testów albo negatywny niezależny werdykt zatrzymuje merge.
- [ ] Zmiana HEAD po review nie zostaje zmergowana na podstawie nieaktualnego odbioru.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-coworker
- bin/ace-test ace-overseer
- bin/ace-test ace-git
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.7.
Następny krok: 8xs.t.pu0.9.
Starsze zakresy do wykorzystania: 8xg.t.sbz.4, 8xg.t.sbz.5.

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
- ace-overseer/docs/usage.md
- ace-git/docs/usage.md
- ace-coworker/handbook/workflow-instructions/coworker/reviewer.wf.md
- ace-coworker/handbook/workflow-instructions/coworker/integrator.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/4-l5-role-coworkera-i-jednoznaczne/8xg.t.sbz.4-l5-role-coworkera-i-jednoznaczne-reguly-ukonczenia.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/5-l6-kolejka-overseera-w-prywatnym/8xg.t.sbz.5-l6-kolejka-overseera-w-prywatnym-ace-task.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/ux/usage.md
