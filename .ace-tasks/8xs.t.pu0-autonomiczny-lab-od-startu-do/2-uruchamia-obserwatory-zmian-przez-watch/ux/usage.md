# Uruchamiać obserwatory zmian przez watch — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Lokalny watch

Wejście / wywołanie: Zarejestrować /watch na źródle projektu i zmienić obserwowany plik.

Oczekiwany wynik: Odbiorca dostaje jedno skuteczne powiadomienie o zmianie.

## Scenariusz 2: Virtiofs

Wejście / wywołanie: Powtórzyć scenariusz zmiany na udziale virtiofs.

Oczekiwany wynik: Działa wykrycie przez obsługiwany mechanizm, bez agentowego sleep-poll.

## Scenariusz 3: Błąd źródła

Wejście / wywołanie: Zarejestrować watch dla niedostępnego źródła.

Oczekiwany wynik: Widoczny błąd zamiast samego wpisu sugerującego działającą obserwację.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/2-uruchamia-obserwatory-zmian-przez-watch/8xs.t.pu0.2-uruchamia-obserwatory-zmian-przez-watch.s.md.
