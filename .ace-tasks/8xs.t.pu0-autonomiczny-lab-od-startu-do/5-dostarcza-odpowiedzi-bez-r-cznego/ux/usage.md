# Dostarczać odpowiedzi bez ręcznego relay — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Odpowiedź zewnętrzna

Wejście / wywołanie: Ask w projekcie, następnie odpowiedź Kapitana przez Hermes.

Oczekiwany wynik: Hermes wywołuje ace-hitl reply dla adresata sprawy; agent kontynuuje.

## Scenariusz 2: Odbiorca po restarcie

Wejście / wywołanie: Dostarczyć odpowiedź podczas nieobecności odbiorcy, potem wznowić.

Oczekiwany wynik: Zapisana odpowiedź jest dostępna i zostaje zauważona.

## Scenariusz 3: Błędny adres

Wejście / wywołanie: Próba dostawy do nieistniejącej sprawy lub niedostępnej maszyny.

Oczekiwany wynik: Jawne niedostarczenie; brak fałszywego sukcesu lub przekierowania do cudzej sprawy.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/5-dostarcza-odpowiedzi-bez-r-cznego/8xs.t.pu0.5-dostarcza-odpowiedzi-bez-r-cznego-relay.s.md.
