---
id: 8xs.t.pu0.d
status: draft
priority: medium
created_at: "2026-10-29 17:13:46"
estimate: medium
dependencies: [8xs.t.pu0.c]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-git/docs/usage.md", "ace-lab/docs/usage.md", "ace-overseer/docs/usage.md", "ace-herdr/docs/usage.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/c-uczy-sugestie-na-decyzjach-kapitana/8xs.t.pu0.c-uczy-sugestie-na-decyzjach-kapitana.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/d-utrwali-operacje-hosta-i-higien/ux/usage.md"], "commands": []}
---

# Utrwalić operacje hosta i higienę

## Cel

Utrwalić powtarzalne operacje hosta i usunąć zbędne pozostałości po odbiorze zastępstw.

## Specyfikacja zachowania

Krok 14/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: medium.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

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

Zachowanie wynika z zaakceptowanego briefu. Szczegóły techniczne wymagają review aktualnych źródeł przed wykonaniem. Brak nowych pytań produktowych blokujących zapis draftu.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

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
