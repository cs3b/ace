# Zapewnić kompletny runtime z instalatora — usage specyfikacji

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

## Uściślenia review

Istniejące install/resume/verify pozostają właścicielami konwergencji. Manifest to
`/etc/lab/ace-lab/install.yml`, bez nowej flagi wyboru manifestu. `install --dry-run`
niczego nie zapisuje; ready wymaga po instalacji osobnego `verify` i wykonanych prób
aktywacji pod kontem docelowym. Obecne offline unknown nie jest dowodem działającego runtime.

Docelowy właściciel przeniesionego rozszerzenia to pakiet assetów `ace-wake` w istniejącym
top-level `ace-wake/`: dodać publikowalne opakowanie gema i włączyć je w discovery/release/test.
`ace-handbook-integration-pi` korzysta z tego pakietu i standardowej projekcji handbook;
nie pozostawia drugiej edytowalnej kopii JS. Instalacja projektuje assets z dokładnej
wersji gema i raportuje potrzebę restartu oraz faktycznie załadowaną wersję. Nie restartuje
po cichu aktywnego wykonawcy. Brak manifestowego pakietu lub dependency closure blokuje odbiór.
Istniejący gem z brakującą zależnością musi zostać naprawiony także wtedy, gdy jego wersja
już figuruje w gem list. Nowsza wersja obecna obok zadeklarowanej nie może przejąć CLI.

Konsumenci: ace-lab, ace-wake, ace-handbook, ace-handbook-integration-pi, discovery/test/release
monorepo. Zakres obejmuje gemspecy, zależności, projekcję rozszerzeń, manifest i dokumentację;
sam update numerów wersji nie wystarcza.
