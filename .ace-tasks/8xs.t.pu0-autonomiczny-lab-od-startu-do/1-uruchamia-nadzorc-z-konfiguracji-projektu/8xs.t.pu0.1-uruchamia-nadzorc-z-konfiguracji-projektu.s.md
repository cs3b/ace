---
id: 8xs.t.pu0.1
status: in-progress
priority: medium
created_at: "2026-10-29 17:13:41"
estimate: large
dependencies: [8xs.t.pu0.0]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-overseer/docs/usage.md, ace-herdr/docs/usage.md, ace-coworker/docs/usage.md, ace-overseer/.ace-defaults/overseer/config.yml, ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/0-zapewni-kompletny-runtime-z-instalatora/8xs.t.pu0.0-zapewni-kompletny-runtime-z-instalatora.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md]
  commands: []
---

# Uruchamiać nadzorcę z konfiguracji projektu

## Cel

Pozwolić wystartować nadzorcy projektu z właściwą rolą, bez ręcznego promptu i skryptu.

## Specyfikacja zachowania

Krok 02/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- ace-overseer start wywołane w skonfigurowanym katalogu projektu ładuje guide z gema, konfigurację projektu oraz właściwy profil modelu/harnessu.
- Nadzorca poznaje zespół, procedury, granice dostępu, eskalacje i definicję zakończenia. Jego rolą jest koordynacja i delegowanie.
- Start tworzy lub odnajduje sesję Herdr i rozpoznaje już działającego właściciela projektu. Guide opisuje docelowy proces; brak jeszcze niedostarczonej zdolności jest jawny.
- Obsługa całego laba jest rozszerzeniem kroku 11; ten wycinek dostarcza samodzielny projekt.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Pierwszy start | W katalogu skonfigurowanego projektu: ace-overseer start | Powstaje sesja nadzorcy z guide z gema i rozpoznanym stanem projektu. |
| Istniejąca sesja | Ponownie ace-overseer start w tym samym projekcie | Wynik identyfikuje istniejącego nadzorcę bez dodatkowej sesji. |
| Nieprzygotowany katalog | ace-overseer start w katalogu bez wymaganej konfiguracji | Brak uruchomienia zgadywanego projektu; komunikat podaje brak konfiguracji. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Nowa sesja ma poprawny cwd, konfigurację, źródło instrukcji i tożsamość nadzorcy.
- [ ] Dwa wywołania start dla tego samego projektu nie tworzą dwóch nadzorców.
- [ ] Brak/niejednoznaczność konfiguracji daje konkretny błąd; nadzorca nie zaczyna implementować jako zastępstwo brakującego coworkera.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-overseer
- bin/ace-test ace-herdr
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.0.
Następny krok: 8xs.t.pu0.2.
Starsze zakresy do wykorzystania: 8xg.t.sbz.6.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Konfiguracja startu należy do istniejącej kaskady `.ace/overseer/config.yml`.
Sekcja `start` ma jawne `scope: project|lab`, `profile` (odwołanie do skonfigurowanego
profilu harnessu/modelu) i `instructions` (źródło handbook). Wartość scope musi pochodzić
z konfiguracji tego katalogu, nie z przypadkowej globalnej listy projektów. Projekt rozpoznaje
kanoniczny root repo; podkatalog/symlink tego rootu prowadzi do tego samego właściciela.
Worktree projektu nie uruchamia drugiego nadzorcy całego projektu. Brak scope/profilu lub
sprzeczny root to błąd przed startem. Na tym etapie scope lab zgłasza niewdrożoną zdolność.

`ace-overseer start [--dry-run] [--format table|json]` zwraca scope, root, źródła
konfiguracji/instrukcji, profil, runtime identity i stan started/reused/blocked. Exit 0
tylko dla gotowego startu/reuse; dry-run pokazuje plan bez sesji, synchronizacji i wywołania
modelu. Żadnych domyślnych modeli z interim skryptu. Start używa Herdr i jego istniejącej
tożsamości sesji; dwa równoczesne wywołania nie tworzą dwóch agentów. Żywa sesja o innym
cwd/profilu/wersji jest konfliktem, nie jest przejmowana. Martwa sesja może zostać zastąpiona
po sprawdzeniu rzeczywistego stanu, z nową tożsamością wskazaną w wyniku.

Guide projektu dostarcza ace-overseer przez handbook, z normalnymi override. Po starcie
agent odczytuje prywatne zadania oraz stan od właścicieli, kontynuuje istniejącą pracę;
przy pustej liście pozostaje idle. Brak coworkera zgłasza, nie przejmuje jego roli.
Konsumenci: ace-overseer, ace-herdr/ace-runtime, ace-lab, handbook i późniejszy lab start.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Nowy start z realnym profilem: potwierdzić cwd, instrukcję załadowaną przez harness, tożsamość i odczyt task-store. |
| 2 | Start kolejno i współbieżnie, z podkatalogu oraz przez symlink/worktree; jedna sesja. Osobno martwy właściciel i żywy konflikt. |
| 3 | Brak/niejednoznaczna konfiguracja, brak profilu, pusty task-store, dry-run: jawny wynik, bez nieuprawnionej delegacji. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-overseer/docs/usage.md
- ace-herdr/docs/usage.md
- ace-coworker/docs/usage.md
- ace-overseer/.ace-defaults/overseer/config.yml
- ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/0-zapewni-kompletny-runtime-z-instalatora/8xs.t.pu0.0-zapewni-kompletny-runtime-z-instalatora.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
