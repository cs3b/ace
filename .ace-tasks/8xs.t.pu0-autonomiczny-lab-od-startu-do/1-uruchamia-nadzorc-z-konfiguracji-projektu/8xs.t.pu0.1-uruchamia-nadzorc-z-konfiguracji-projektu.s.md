---
id: 8xs.t.pu0.1
status: draft
priority: medium
created_at: "2026-10-29 17:13:41"
estimate: large
dependencies: [8xs.t.pu0.0]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-overseer/docs/usage.md", "ace-herdr/docs/usage.md", "ace-coworker/docs/usage.md", "ace-overseer/.ace-defaults/overseer/config.yml", "ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/0-zapewni-kompletny-runtime-z-instalatora/8xs.t.pu0.0-zapewni-kompletny-runtime-z-instalatora.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/ux/usage.md"], "commands": []}
---

# Uruchamiać nadzorcę z konfiguracji projektu

## Cel

Pozwolić wystartować nadzorcy projektu z właściwą rolą, bez ręcznego promptu i skryptu.

## Specyfikacja zachowania

Krok 02/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

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
- ace-herdr/docs/usage.md
- ace-coworker/docs/usage.md
- ace-overseer/.ace-defaults/overseer/config.yml
- ace-overseer/handbook/workflow-instructions/overseer/queue.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/0-zapewni-kompletny-runtime-z-instalatora/8xs.t.pu0.0-zapewni-kompletny-runtime-z-instalatora.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/ux/usage.md
