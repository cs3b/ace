---
id: 8xs.t.pu0.a
status: draft
priority: medium
created_at: "2026-10-29 17:13:45"
estimate: large
dependencies: [8xs.t.pu0.9]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-lab/docs/usage.md", "ace-overseer/docs/usage.md", "ace-herdr/docs/usage.md", "ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md", "ace-lab/.ace-defaults/lab/config.yml", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/8xs.t.pu0.9-dostarcza-wydania-i-zamyka-cykle.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/a-uruchamia-projekty-z-katalogu-laba/ux/usage.md"], "commands": []}
---

# Uruchamiać projekty z katalogu laba

## Cel

Zapewnić jeden zewnętrzny punkt startu dla wszystkich skonfigurowanych projektów.

## Specyfikacja zachowania

Krok 11/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- ace-overseer start w katalogu laba rozpoznaje zakres lab, ładuje labowy guide i istniejącą konfigurację projektów.
- Zapewnia właściwe spaces Herdr i uruchamia lub odnajduje nadzorców w katalogach projektów.
- Nadzorca laba agreguje stan i eskalacje oraz deleguje do nadzorców projektów. Nie przejmuje ich zadań ani prywatnego stanu.
- Bezpośredni start projektu i późniejszy start laba rozpoznają tę samą żywą sesję; ponowny start nie dubluje nadzorców.
- Brak gotowości jednego projektu jest widoczny osobno; zdrowe projekty mogą działać dalej.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Lab z dwoma projektami | W katalogu laba: ace-overseer start | Powstają/odnajdują się spaces i nadzorcy obu projektów z ich konfiguracją. |
| Projekt wcześniej uruchomiony | Wystartować projekt samodzielnie, potem cały lab | Nadzorca laba rozpoznaje istniejącą sesję projektu. |
| Jeden projekt niedostępny | Uruchomić lab ze zdrowym i niegotowym projektem | Zdrowy projekt działa, a brak drugiego jest konkretnie raportowany. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Start jednego laba przygotowuje co najmniej dwa skonfigurowane projekty i ich nadzorców.
- [ ] Ponowienie startu oraz dołączenie już działającego projektu nie tworzą duplikatów.
- [ ] Uszkodzona konfiguracja jednego projektu daje częściową gotowość z przyczyną, bez fałszywego sukcesu całego laba.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-overseer
- bin/ace-test ace-lab
- bin/ace-test ace-herdr
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.9.
Następny krok: 8xs.t.pu0.b.
Starsze zakresy do wykorzystania: 8xg.t.sbz.6, 8xg.t.sbz.7.

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
- ace-lab/docs/usage.md
- ace-overseer/docs/usage.md
- ace-herdr/docs/usage.md
- ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md
- ace-lab/.ace-defaults/lab/config.yml
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/8xs.t.pu0.9-dostarcza-wydania-i-zamyka-cykle.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/a-uruchamia-projekty-z-katalogu-laba/ux/usage.md
