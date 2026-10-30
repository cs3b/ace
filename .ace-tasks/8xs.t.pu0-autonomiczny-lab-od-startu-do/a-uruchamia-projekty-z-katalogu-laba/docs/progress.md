# Postęp 8xs.t.pu0.a — start całego laba (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Start na żywym herdr z prawdziwymi
space'ami — odbiór na labie odroczony na koniec programu.

## Zrealizowane w źródłach

1. **`ace-lab Molecules::ProjectLocations`** — wewnętrzny odczyt lokalizacji
   projektów z istniejącej konfiguracji topologii (`topology.projects`
   id/path, raw cascade — normalizacja/publiczna projekcja celowo ścieżek
   nie niosą); brak path = błąd TEGO projektu; publiczne CLI zachowuje
   sanityzowaną projekcję; żadnej drugiej listy w overseerze.
2. **Scope lab w `ace-overseer start`** (`StartOrchestrator#lab_start`):
   - lista projektów z topologii; root laba = katalog koordynacji z własnym
     _overseer; ten sam katalog jako lab i projekt = odmowa bez zgadywania;
   - lab tworzy/reużywa swój space herdr (`overseer-lab`, po tytule);
   - każdy projekt startuje przez TĘ SAMĄ operację co start samodzielny
     (własna kaskada przez `Ace::Overseer.config_at` z ominięciem
     test-mode mocków, własny kanoniczny root i tożsamość sesji);
   - statusy: ready (wszystkie started/reused; pusta lista = ważny idle),
     partial (niesprawny projekt raportowany z konkretną przyczyną,
     zdrowe kontynuują), blocked (nieczytelna topologia/konflikt ról);
   - powtórzenie naprawia tylko braki (reuse żywych, bez restartów i bez
     zamykania ręcznych pane); dry-run bez space/sesji; table/json/quiet wg
     kontraktu .1; exit 0 tylko ready.
3. **Guide labowy** (`wfi://overseer/lab-start`): koordynacja między
   projektami, delegacja do nadzorców projektów, eskalacje między-projektowe,
   bez przejmowania zadań/prywatnego stanu projektów.
4. `StartContract` dopuszcza scope lab (lab guide jako instructions);
   dokumentacja usage + CHANGELOG.

## Dowody

- `bin/ace-test ace-overseer` — 399 testów, 0 fail; nowe
  `lab_start_test` (6): lab z dwoma projektami (oba started, jeden space,
   tab per projekt z cwd projektu), powtórny start = reuse bez duplikatów
  (space 1, wszystkie reused), niezdrowy projekt = partial z przyczyną przy
  działającym zdrowym, pusta lista = ready/idle 0, konflikt ról = blocked,
  dry-run bez side-efektów.
- `bin/ace-test ace-lab` — 621 testów, 0 fail (ProjectLocations w tree).
- Naprawiony przy okazji: `config_at` omija test-mode mocki (thread-local
  test mode zafałszowywał odczyt kaskady w pełnym suite).

## Granice / odroczone

- Odbiór na labie: prawdziwe space'y Herdr, ≥2 skonfigurowane projekty,
  dołączenie już działającego projektu, praca na prawdziwej topologii z
  ace-lab install; publikacja gemów.
