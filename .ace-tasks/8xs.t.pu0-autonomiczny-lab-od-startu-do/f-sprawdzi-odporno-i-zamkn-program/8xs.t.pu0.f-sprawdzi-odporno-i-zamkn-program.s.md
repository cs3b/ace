---
id: 8xs.t.pu0.f
status: draft
priority: medium
created_at: "2026-10-29 17:13:47"
estimate: large
dependencies: [8xs.t.pu0.e]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-lab/docs/usage.md", "ace-overseer/docs/usage.md", "ace-coworker/docs/usage.md", "ace-hitl/docs/usage.md", "ace-handbook-integration-pi/docs/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/e-potwierdzi-pe-ny-cykl-zimnego/8xs.t.pu0.e-potwierdzi-pe-ny-cykl-zimnego-startu.s.md"], "commands": []}
---

# Sprawdzić odporność i zamknąć program

## Cel

Potwierdzić odporność procesu na przerwania i zamknąć program wyłącznie na podstawie dowodów.

## Specyfikacja zachowania

Krok 16/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- Wykonać próby restartu nadzorcy/coworkera na granicach przekazań, powtórzonego zdarzenia, utraty reply, zmiany HEAD i awarii źródła obserwacji.
- Sprawdzić co najmniej 30 minut zdrowej bezczynności: zero dodatkowych wywołań modelu po uspokojeniu stanu; techniczny polling jest dozwolony.
- Po odzyskaniu dostępności proces rozpoznaje trwały stan i kontynuuje bez zgubienia pracy lub ponowienia zakończonych skutków.
- Każdy znaleziony defekt naprawić w zakresie odpowiedzialnego komponentu, ponowić jego scenariusz i potwierdzić cały dotknięty przebieg.
- Raport końcowy mapuje dowody na kryteria tej rodziny oraz gad.2/sbz.9. Statusy historycznych programów zmieniać wyłącznie po potwierdzeniu ich kryteriów, nigdy na podstawie samej deklaracji done.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Przerwane przekazanie | Restartować na granicy raportu, odpowiedzi oraz publikacji/instalacji | Odzyskanie kontynuuje właściwy etap bez powielenia jego zakończonych skutków. |
| Wrong-head i lost-reply | Zmienić HEAD po review; osobno utracić dostawę odpowiedzi przed zapisem | Nieaktualny review nie dopuszcza merge; niedostarczona odpowiedź pozostaje wykrywalna i może zostać ponowiona. |
| Zero-idle i awaria obserwacji | Obserwować 30 minut bez zmian, następnie przerwać źródło i przywrócić | Zero dodatkowych tur w ciszy; jawna awaria i skuteczne odzyskanie obserwacji. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Każda próba awarii ma wejściowy stan, oczekiwany wynik, faktyczne dowody i wynik ponowienia po naprawie.
- [ ] Nie ma zagubionych decyzji, podwójnych zakończonych operacji ani bezproduktywnych tur w oknie zero-idle.
- [ ] Raport zamykający rozróżnia potwierdzone kryteria od pozostających ograniczeń; brak niespełnionych wymaganych kryteriów do zamknięcia rodziny.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Wykonanie scenariuszy akceptacji przez właściwy runner ace-test/ace-test-suite; polecenia domenowe wskazuje tabela. Wyniki i rzeczywiste ścieżki runtime zapisać przy tasku.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.e.
Następny krok: odbiór i zamknięcie taska nadrzędnego.
Starsze zakresy do wykorzystania: 8xg.t.sbz.8, 8xg.t.sbz.9.

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
- ace-lab/docs/usage.md
- ace-overseer/docs/usage.md
- ace-coworker/docs/usage.md
- ace-hitl/docs/usage.md
- ace-handbook-integration-pi/docs/usage.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8-l9-pelny-przeplyw-i-scenariusze/8xg.t.sbz.8-l9-pelny-przeplyw-i-scenariusze-awarii-przed.s.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/e-potwierdzi-pe-ny-cykl-zimnego/8xs.t.pu0.e-potwierdzi-pe-ny-cykl-zimnego-startu.s.md
