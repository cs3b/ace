# Utrwalić operacje hosta i higienę — draft usage

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Powtarzalny sync

Wejście / wywołanie: Uruchomić udokumentowaną operację hosta na ustalonych repozytoriach.

Oczekiwany wynik: Wynik zawiera rzeczywiste źródłowe i docelowe SHA oraz rezultat sprawdzenia.

## Scenariusz 2: Usunięcie protez

Wejście / wywołanie: Po odbiorze zastępstw usunąć wskazane stare skrypty/config i wykonać zimny start.

Oczekiwany wynik: Start używa zasobów gema i właściwego konta, bez zależności od protez.

## Scenariusz 3: Rozbieżność lub aktywny zasób

Wejście / wywołanie: Wykryć divergence mirroru albo pozostałość używaną przez aktywną sprawę.

Oczekiwany wynik: Operacja zgłasza konkretną sytuację i zachowuje wartościową pracę.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/d-utrwali-operacje-hosta-i-higien/8xs.t.pu0.d-utrwali-operacje-hosta-i-higien.s.md.
