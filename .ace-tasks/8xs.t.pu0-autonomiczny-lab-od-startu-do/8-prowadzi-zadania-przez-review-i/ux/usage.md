# Prowadzić zadania przez review i merge — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Poprawny kandydat

Wejście / wywołanie: Worker dostarcza PR, reviewer sprawdza go, integrator odbiera.

Oczekiwany wynik: Wykonane testy i niezależny werdykt wraz z wymaganym approval prowadzą do merge.

## Scenariusz 2: Zmiana HEAD

Wejście / wywołanie: Zmienić kandydata po review przed merge.

Oczekiwany wynik: Następuje właściwa ponowna weryfikacja nowego kandydata.

## Scenariusz 3: Brak dowodu

Wejście / wywołanie: Zgłosić sukces bez wykonanych testów lub z nierozwiązanym wymaganym findingiem.

Oczekiwany wynik: Gate zatrzymuje integrację i pokazuje brakującą podstawę.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/8xs.t.pu0.8-prowadzi-zadania-przez-review-i-merge.s.md.
