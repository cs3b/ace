# Obserwować zmiany PR oraz repozytorium — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Nowy HEAD

Wejście / wywołanie: Zmienić HEAD obserwowanego PR przy działającym nadzorcy.

Oczekiwany wynik: Nadzorca widzi nowego kandydata i nie używa starego review jako aktualnego.

## Scenariusz 2: Powtarzany stan

Wejście / wywołanie: Odpytywać PR bez zmian.

Oczekiwany wynik: Zero powtarzających się wybudzeń modelu.

## Scenariusz 3: Awaria forge

Wejście / wywołanie: Przerwać dostęp do API i następnie go przywrócić.

Oczekiwany wynik: Widoczny błąd źródła, następnie odzyskanie obserwacji i rozpoznanie zmian.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/4-obserwowa-zmiany-pr-oraz-repozytorium/8xs.t.pu0.4-obserwowa-zmiany-pr-oraz-repozytorium.s.md.
