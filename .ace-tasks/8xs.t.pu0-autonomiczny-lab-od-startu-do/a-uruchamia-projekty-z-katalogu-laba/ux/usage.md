# Uruchamiać projekty z katalogu laba — draft usage

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
