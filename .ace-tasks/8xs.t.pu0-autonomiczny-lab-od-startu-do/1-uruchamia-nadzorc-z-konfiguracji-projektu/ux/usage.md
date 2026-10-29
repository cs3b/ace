# Uruchamiać nadzorcę z konfiguracji projektu — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Pierwszy start

Wejście / wywołanie: W katalogu skonfigurowanego projektu: ace-overseer start.

Oczekiwany wynik: Powstaje sesja nadzorcy z guide z gema i rozpoznanym stanem projektu.

## Scenariusz 2: Istniejąca sesja

Wejście / wywołanie: Ponownie ace-overseer start w tym samym projekcie.

Oczekiwany wynik: Wynik identyfikuje istniejącego nadzorcę bez dodatkowej sesji.

## Scenariusz 3: Nieprzygotowany katalog

Wejście / wywołanie: ace-overseer start w katalogu bez wymaganej konfiguracji.

Oczekiwany wynik: Brak uruchomienia zgadywanego projektu; komunikat podaje brak konfiguracji.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/1-uruchamia-nadzorc-z-konfiguracji-projektu/8xs.t.pu0.1-uruchamia-nadzorc-z-konfiguracji-projektu.s.md.
