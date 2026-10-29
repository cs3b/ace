---
id: 8xs.t.pu0.0
status: in-progress
priority: medium
created_at: "2026-10-29 17:13:40"
estimate: large
dependencies: []
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-lab/docs/usage.md, ace-handbook-integration-pi/docs/usage.md, ace-lab/.ace-defaults/lab/config.yml, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/0-zapewni-kompletny-runtime-z-instalatora/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, ace-test-runner/docs/usage.md]
  commands: []
---

# Zapewnić kompletny runtime z instalatora

## Cel

Usunąć ręczne uzupełnianie środowiska przed każdym odbiorem zmian.

## Specyfikacja zachowania

Krok 01/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- Instalator uzgadnia manifest i rzeczywiste wersje gemów wraz z wymaganymi zależnościami przechodnimi; wykorzystuje istniejący wynik sbz.7.
- Rozszerzenia harnessu pochodzą z odpowiedniego zainstalowanego gema. Wynik wskazuje ścieżki CLI/gemów/instrukcji oraz potrzebę restartu procesów.
- Weryfikacja działa pod kontem wykonawcy. Tryb installed pozostaje zachowany; nie korzysta ze źródeł projektu jako zastępstwa brakującej instalacji.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Instalacja pod docelowym kontem | ace-lab install z manifestem docelowego laba | Docelowe CLI oraz rozszerzenia działają z zadeklarowanego zestawu wersji. |
| Ponowienie po przerwaniu | Powtórzyć ace-lab install dla tego samego manifestu po przerwanym kroku | Instalacja osiąga stan docelowy bez ręcznego kopiowania zasobów. |
| Brak zależności | Uruchomić odbiór ze zbiorem gemów bez wymaganej zależności przechodniej | Wynik wskazuje konkretny brak; nie przełącza na checkout ani nie zgłasza gotowości. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Świeża instalacja udostępnia komplet zależności, w tym json gdy jest wymagany, bez ręcznych komend naprawczych.
- [ ] Ponowne uzgodnienie tego samego manifestu nie psuje gotowego środowiska; przerwane uzgodnienie można dokończyć.
- [ ] Nieudana instalacja lub niedostępna zależność daje brak gotowości, a nie pozytywny wynik.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-lab
- bin/ace-test ace-handbook-integration-pi
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: brak; pierwszy wycinek.
Następny krok: 8xs.t.pu0.1.
Starsze zakresy do wykorzystania: 8xg.t.sbz.7.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

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

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Czysty runtime: install → projekcja → rzeczywisty start CLI/harnessu; wersje/ścieżki i dependency closure zgodne z manifestem. |
| 2 | Przerwać po gem install i po projekcji; ponowić, także z dodatkową nowszą wersją oraz brakiem json przy już obecnym gemie. |
| 3 | Nieosiągalna zależność lub stara aktywna extension: brak ready; dry-run bez zmian plików i procesów. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-lab/docs/usage.md
- ace-handbook-integration-pi/docs/usage.md
- ace-lab/.ace-defaults/lab/config.yml
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/7-l8-instalacja-nowego-laba-i/8xg.t.sbz.7-l8-instalacja-nowego-laba-i-dodawanie-projektu.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/0-zapewni-kompletny-runtime-z-instalatora/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
