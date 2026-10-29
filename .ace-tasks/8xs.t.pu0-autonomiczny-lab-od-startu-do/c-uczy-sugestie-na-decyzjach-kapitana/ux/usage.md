# Uczyć sugestie na decyzjach Kapitana — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Korekta jako przykład

Wejście / wywołanie: Kapitan odrzuca sugestię i podaje inną odpowiedź; później pojawia się podobne pytanie.

Oczekiwany wynik: Nowa propozycja ma dostęp do rzeczywistej decyzji i odnosi się do jej kontekstu.

## Scenariusz 2: Brak precedensu

Wejście / wywołanie: Zadać pytanie bez odpowiedniej historii.

Oczekiwany wynik: Agent zaznacza brak przykładów i nie wymyśla wcześniejszej zgody.

## Scenariusz 3: Sekret i izolacja

Wejście / wywołanie: W historii są sprawy OTP lub sprawa innego niedostępnego projektu.

Oczekiwany wynik: Wartości sekretów i niedozwolony kontekst nie są używane ani ujawniane.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/8xs.t.pu0.c-uczy-sugestie-na-decyzjach-kapitana.s.md.
