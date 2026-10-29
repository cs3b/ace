# Reagować na lokalny stan projektu — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Raport końca pracy

Wejście / wywołanie: Coworker raportuje wynik; nadzorca obserwuje projekt.

Oczekiwany wynik: Nadzorca przetwarza raport i wybiera kolejny etap zgodny z zależnościami.

## Scenariusz 2: Restart

Wejście / wywołanie: Zatrzymać nadzorcę, dostarczyć raport, uruchomić ace-overseer start.

Oczekiwany wynik: Oczekujący raport zostaje obsłużony bez zgubienia lub zdublowania pracy.

## Scenariusz 3: Cisza i awaria

Wejście / wywołanie: Pozostawić stan bez zmian, następnie odłączyć źródło.

Oczekiwany wynik: Cisza nie uruchamia modelu; awaria jest odróżniona od zdrowego braku zmian.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/3-reagowa-na-lokalny-stan-projektu/8xs.t.pu0.3-reagowa-na-lokalny-stan-projektu.s.md.
