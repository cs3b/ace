---
id: 8xs.t.pu0.d
status: pending
priority: medium
created_at: "2026-10-29 17:13:46"
estimate: medium
dependencies: [8xs.t.pu0.c]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-git/docs/usage.md, ace-lab/docs/usage.md, ace-overseer/docs/usage.md, ace-herdr/docs/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/8xs.t.pu0.c-uczy-sugestie-na-decyzjach-kapitana.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/d-utrwali-operacje-hosta-i-higien/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md]
  commands: []
---

# Utrwalić operacje hosta i higienę

## Cel

Utrwalić powtarzalne operacje hosta i usunąć zbędne pozostałości po odbiorze zastępstw.

## Specyfikacja zachowania

Krok 14/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: medium.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- Istniejący reviewowany przebieg synchronizacji Forgejo/GitHub staje się powtarzalną operacją hosta z jawnym celem, stanem źródła/celu i wynikiem.
- Usunąć zbędnego collaboratora lab-overseer-ace po sprawdzeniu właściwych kont i zachowaniu wymaganych dostępów.
- Usunąć zastąpione interim-start, ręczny OPERATION-GUIDE.md i nieużywane konfiguracje trasy po sprawdzeniu działania ścieżek z gemów.
- Zachować wartościowy salvage i aktywne zasoby. Zgłoszone domknięcie af68f8fc1cc7 jest stanem wejściowym do sprawdzenia, nie instrukcją ponownego resetu lub czyszczenia.
- Usunięcie pojedynczego pane w Herdr pozostaje osobnym follow-upem; nie zamykać całego tab jako zastępstwa.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Powtarzalny sync | Uruchomić udokumentowaną operację hosta na ustalonych repozytoriach | Wynik zawiera rzeczywiste źródłowe i docelowe SHA oraz rezultat sprawdzenia. |
| Usunięcie protez | Po odbiorze zastępstw usunąć wskazane stare skrypty/config i wykonać zimny start | Start używa zasobów gema i właściwego konta, bez zależności od protez. |
| Rozbieżność lub aktywny zasób | Wykryć divergence mirroru albo pozostałość używaną przez aktywną sprawę | Operacja zgłasza konkretną sytuację i zachowuje wartościową pracę. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Operator wykonuje reviewowany sync powtarzalnie i dostaje sprawdzalny wynik zgodności właściwych repozytoriów.
- [ ] Po sprzątaniu nowy start działa z guide i skryptami z gemów.
- [ ] Raport zawiera usunięte pozostałości oraz zachowane aktywne zasoby; divergence sync nie jest rozwiązywana destrukcyjnym nadpisaniem.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-git
- bin/ace-test ace-lab
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.c.
Następny krok: 8xs.t.pu0.e.
Starsze zakresy do wykorzystania: raport closeoutu oraz istniejące narzędzia hosta.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Sync jest operacją hosta dla jawnego źródła/celu/ref w istniejącym workflow Git.
Dla tej rodziny źródłem wdrożonego laba jest wskazany Forgejo cs3b/ace, a mirror GitHub
cs3b/ace; przed każdym działaniem odczytać oba pełne SHA. Identity source=target to
no-op. Domyślnie tylko fast-forward; divergence wymaga osobnego reviewowanego uzgodnienia,
bez reset, force ani kasowania refów. Odczytane af68f8fc1 jest historyczną bazą, nie SHA
do bezwarunkowego narzucenia aktualnemu GitHub.

Po odbiorze .1/.a/.5 przygotować konkretny wykaz pozostałości i odczytać ich użycie.
Usuwać wyłącznie zastąpione interim-start, ręczny guide, duplikaty route i potwierdzone
zbędne uprawnienie collaboratora. Ta sama nazwa w innym repo lub aktywny zasób nie
kwalifikuje się do usunięcia. Zbędne granty zmienia właściciel platformy, nie manifest
install, który obecnie tylko powiększa grants. Salvage i historia HITL pozostają.

Konsumenci/deliverables: utrwalony workflow operacji hosta, jego scenariusz dry-run,
odczyt dowodów remote, aktualny guide i wykaz sprzątania. Jeśli potrzebna jest zmiana
narzędzia, należy do ace-git/adaptera lub ace-lab, bez nowego skryptu hardkodującego lab.
Pane-close nadal poza zakresem; nie zastępować go zamknięciem całego tab.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Host sync: source/target/ref i SHA przed/po, ff-only oraz ponowienie identity no-op; źródło/cel odwrócone wykryte w planie. |
| 2 | Po usunięciu konkretnych zastąpionych plików zimny start używa gemów; oba projekty i reply działają. |
| 3 | Divergence, aktywny route/case, salvage i obcy collaborator: brak destrukcyjnego działania, jawna lista preserved/removed z przyczyną. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-git/docs/usage.md
- ace-lab/docs/usage.md
- ace-overseer/docs/usage.md
- ace-herdr/docs/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/8xs.t.pu0.c-uczy-sugestie-na-decyzjach-kapitana.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/d-utrwali-operacje-hosta-i-higien/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
