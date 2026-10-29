# Zamykać sprawy HITL bez sierot — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Zamknięcie sprawy

Wejście / wywołanie: Dostarczyć i zastosować odpowiedź, zakończyć czynność.

Oczekiwany wynik: Sprawa jest zamknięta, niepotrzebny watch nie wybudza odbiorcy.

## Scenariusz 2: Duplikat i restart

Wejście / wywołanie: Ponowić odpowiedź po restarcie odbiorcy.

Oczekiwany wynik: Brak ponownego wykonania zakończonej operacji.

## Scenariusz 3: Późna odpowiedź i sweep

Wejście / wywołanie: Odpowiedzieć na zamkniętą sprawę i przejrzeć pozostałości transportu.

Oczekiwany wynik: Brak automatycznej zmiany decyzji; aktywne sprawy i historia pozostają.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/6-zamyka-sprawy-hitl-bez-sierot/8xs.t.pu0.6-zamyka-sprawy-hitl-bez-sierot.s.md.
