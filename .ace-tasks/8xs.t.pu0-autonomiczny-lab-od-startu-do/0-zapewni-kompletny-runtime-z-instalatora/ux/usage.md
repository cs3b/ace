# Zapewnić kompletny runtime z instalatora — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Instalacja pod docelowym kontem

Wejście / wywołanie: ace-lab install z manifestem docelowego laba.

Oczekiwany wynik: Docelowe CLI oraz rozszerzenia działają z zadeklarowanego zestawu wersji.

## Scenariusz 2: Ponowienie po przerwaniu

Wejście / wywołanie: Powtórzyć ace-lab install dla tego samego manifestu po przerwanym kroku.

Oczekiwany wynik: Instalacja osiąga stan docelowy bez ręcznego kopiowania zasobów.

## Scenariusz 3: Brak zależności

Wejście / wywołanie: Uruchomić odbiór ze zbiorem gemów bez wymaganej zależności przechodniej.

Oczekiwany wynik: Wynik wskazuje konkretny brak; nie przełącza na checkout ani nie zgłasza gotowości.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/0-zapewni-kompletny-runtime-z-instalatora/8xs.t.pu0.0-zapewni-kompletny-runtime-z-instalatora.s.md.
