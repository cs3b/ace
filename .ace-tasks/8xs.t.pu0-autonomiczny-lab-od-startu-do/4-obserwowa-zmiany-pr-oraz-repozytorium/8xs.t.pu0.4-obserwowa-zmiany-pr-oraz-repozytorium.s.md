---
id: 8xs.t.pu0.4
status: draft
priority: medium
created_at: "2026-10-29 17:13:42"
estimate: medium
dependencies: [8xs.t.pu0.3]
tags: []
parent: 8xs.t.pu0
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", "docs/lab-flow.md", "docs/tools.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md", "ace-overseer/docs/usage.md", "ace-git/docs/usage.md", "ace-handbook-integration-pi/docs/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/3-reagowa-na-lokalny-stan-projektu/8xs.t.pu0.3-reagowa-na-lokalny-stan-projektu.s.md", ".ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/4-obserwowa-zmiany-pr-oraz-repozytorium/ux/usage.md"], "commands": []}
---

# Obserwować zmiany PR oraz repozytorium

## Cel

Zastąpić ręczne sprawdzanie PR-ów reakcją na istotne zmiany zdalne.

## Specyfikacja zachowania

Krok 05/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: medium.
Wejście: skonfigurowane środowisko i stan wymagany przez poprzedni krok. Wyjście: obserwowalny rezultat poniżej.

- Konfigurowana obserwacja PR/repo korzysta z istniejących adapterów forge i uprawnień.
- Nowy HEAD, review, approval, merge i zamknięcie PR są widoczne dla właściwego nadzorcy.
- Techniczne odpytywanie źródła nie uruchamia modelu dla identycznych wyników. Błąd API nie jest traktowany jako pusta lista.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Nowy HEAD | Zmienić HEAD obserwowanego PR przy działającym nadzorcy | Nadzorca widzi nowego kandydata i nie używa starego review jako aktualnego. |
| Powtarzany stan | Odpytywać PR bez zmian | Zero powtarzających się wybudzeń modelu. |
| Awaria forge | Przerwać dostęp do API i następnie go przywrócić | Widoczny błąd źródła, następnie odzyskanie obserwacji i rozpoznanie zmian. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Nowy HEAD i review prowadzą do rozpoznania zmiany oraz właściwej kontynuacji.
- [ ] Powtarzane odczyty identycznego stanu nie generują kolejnych tur modelu.
- [ ] Niedostępny forge daje widoczną awarię; po przywróceniu dostępu zmiana zostaje rozpoznana.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-overseer
- bin/ace-test ace-git
- bin/ace-test ace-handbook-integration-pi
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.3.
Następny krok: 8xs.t.pu0.5.
Starsze zakresy do wykorzystania: 8xg.t.sbz.6.

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
- ace-overseer/docs/usage.md
- ace-git/docs/usage.md
- ace-handbook-integration-pi/docs/usage.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/3-reagowa-na-lokalny-stan-projektu/8xs.t.pu0.3-reagowa-na-lokalny-stan-projektu.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/4-obserwowa-zmiany-pr-oraz-repozytorium/ux/usage.md
