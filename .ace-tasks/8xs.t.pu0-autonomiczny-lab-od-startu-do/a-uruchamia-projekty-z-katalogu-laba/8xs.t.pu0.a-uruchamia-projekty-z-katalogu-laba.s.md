---
id: 8xs.t.pu0.a
status: pending
priority: medium
created_at: "2026-10-29 17:13:45"
estimate: large
dependencies: [8xs.t.pu0.9]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-lab/docs/usage.md, ace-overseer/docs/usage.md, ace-herdr/docs/usage.md, ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md, ace-lab/.ace-defaults/lab/config.yml, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/8xs.t.pu0.9-dostarcza-wydania-i-zamyka-cykle.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/a-uruchamia-projekty-z-katalogu-laba/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md]
  commands: []
---

# Uruchamiać projekty z katalogu laba

## Cel

Zapewnić jeden zewnętrzny punkt startu dla wszystkich skonfigurowanych projektów.

## Specyfikacja zachowania

Krok 11/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

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

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Rozszerzyć kontrakt start z kroku 02 o scope lab w konfiguracji katalogu laba.
Lista projektów i ich kanoniczne lokalizacje pochodzi z istniejącej konfiguracji
ace-lab (`topology.projects`: id/path/remote), z normalnym odczytem dopuszczonego zakresu.
Nie wyprowadzać path z publicznego id/label ani z nazwy repo; nie tworzyć drugiej listy
w overseer. ace-lab udostępnia wewnętrzny odczyt lokalizacji dla startu, zachowując
sanityzowaną publiczną projekcję. Brak path jest błędem danego projektu.

Lab tworzy/reużywa swój space i sesję, a projekt startuje przez tę samą operację co start
samodzielny. Tożsamość projektu: kanoniczny root + skonfigurowane id; nazwa tab nie wystarcza.
Root laba jest osobnym katalogiem koordynacji z własnym _overseer. Jeśli ten sam katalog
deklaruje sprzeczne role lab/project, start odmawia bez zgadywania. Pusta lista projektów
daje ready/idle z liczbą 0; uszkodzony projekt daje partial i nonzero, zdrowe kontynuują.
Powtórzenie start naprawia tylko braki. Nie zamyka ręcznych pane, nie restartuje zdrowych.

Status pokazuje osobne wyniki projektów i eskalacje. `--dry-run` nie tworzy space/sesji
ani tasków; table/json/quiet zachowują kontrakt .1. Konsumenci: ace-lab topology/registry,
ace-overseer start/status, ace-herdr/ace-runtime i guide obu ról.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Lab z dwoma projektami: dwa właściwe cwd/profile/spaces, odrębne task-store i agregacja eskalacji; także pusta lista. |
| 2 | Projekt → lab, lab → projekt, współbieżne start i restart: dokładnie jeden właściciel projektu i odtworzona obserwacja. |
| 3 | Brak path, niedostępny projekt, kolizja id/root i sprzeczny scope: partial/blocked z przyczyną; zdrowe działają, dry-run bez skutków. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

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
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
