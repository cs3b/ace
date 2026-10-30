# Uruchamiać projekty z katalogu laba — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Lab z dwoma projektami

Wejście / wywołanie: W katalogu laba: ace-overseer start.

Oczekiwany wynik: Powstają/odnajdują się spaces i nadzorcy obu projektów z ich konfiguracją.

## Scenariusz 2: Projekt wcześniej uruchomiony

Wejście / wywołanie: Wystartować projekt samodzielnie, potem cały lab.

Oczekiwany wynik: Nadzorca laba rozpoznaje istniejącą sesję projektu.

## Scenariusz 3: Jeden projekt niedostępny

Wejście / wywołanie: Uruchomić lab ze zdrowym i niegotowym projektem.

Oczekiwany wynik: Zdrowy projekt działa, a brak drugiego jest konkretnie raportowany.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/a-uruchamia-projekty-z-katalogu-laba/8xs.t.pu0.a-uruchamia-projekty-z-katalogu-laba.s.md.

## Uściślenia review

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
