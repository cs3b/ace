# Wyniki: 8xg.t.sbz.6.3 — Pokazywać blokady, awarie i brak danych (L7.4)

Data: 2026-10-19. Branch: `t-sbz-wave-3`.

## Co zostało zrobione

`ace-overseer status` (powierzchnia z L7.2, bez drugiego dashboardu) otwiera się
teraz sekcją `-- attention` wyliczaną na żywo z już zebranych źródeł plus
read-only `Molecules::HitlInbox`. Nowy organizm `Organisms::StatusAttention`
(czysty, bez nowego stanu — ADR-034) dzieli trzy kategorie:

- **BLOCKER** — taski startowalne (`pending` w drzewie projektowym lub
  `_overseer`) z niespełnionymi zależnościami oraz taski jawnie `blocked`;
  każdy wiersz ma konkretny powód per zależność z `Atoms::DependencyReadiness`
  (status poprzednika, brakująca/cykliczna zależność) i `next_action`.
- **FAILURE** — błędy źródeł (z origin), assignmenty `failed`/`stalled`,
  błędy probe'a wykonawcy per worktree, eskalacje (oczekujące pytania ace-hitl).
- **MISSING DATA** — wyłączone źródła, nieznane klucze `status_sources`,
  nieczytelne drzewo tasków (gotowość zależności zweryfikowana niepełnie),
  nieznany status taska, nieznany stan wykonawcy (`unknown`/`unparseable` —
  worktree nie jest wolny), nieosiągalny inbox hitl.

Każdy wiersz ma `next_action`. Brak danych nigdy nie potwierdza wolnego
worktree ani zakończonego zadania (kontrakt programu). Gdy nic nie wymaga
uwagi, sekcja mówi to wprost (`-- attention: none`).

Kontrakt JSON: `{sources:, unknown_keys:, attention: {blockers:, failures:,
missing_data:}}` — każdy wiersz attention ma `kind`, identyfikator i
`next_action`.

Zmienione pliki:

- `ace-overseer/lib/ace/overseer/organisms/status_attention.rb` (nowy)
- `ace-overseer/lib/ace/overseer/organisms/status_collector.rb`
  (collect_sources dokłada `attention`; tabela i JSON je renderują)
- `ace-overseer/lib/ace/overseer.rb` (require)
- `ace-overseer/test/fast/organisms/status_attention_test.rb` (nowy, 19 testów)
- `ace-overseer/test/fast/organisms/status_sources_test.rb`
  (hermetyczny wstrzykiwany skaner attention w helperze)
- `ace-overseer/CHANGELOG.md`, `ace-overseer/docs/usage.md`,
  `docs/lab-flow.md` (wiersz L7 → Shipped; człon L7.4 domyka rodzinę L7)

## Mapowanie kryteriów odbioru

- „Overseer widzi, na czyją decyzję lub jaki wynik czeka, i może kontynuować
  po usunięciu przeszkody."
  - Eskalacje: `test_pending_hitl_question_is_an_escalation_failure` —
    oczekujące pytanie ace-hitl pojawia się jako FAILURE z `next_action`
    „answer question <id> via ace-hitl".
  - Blokady: `test_pending_task_with_unsatisfied_dependency_is_a_blocker_with_reason`,
    `test_missing_dependency_is_a_blocker_not_a_free_pass`,
    `test_overseer_tree_blocked_task_appears_even_with_satisfied_dependencies`,
    `test_blockers_from_overseer_tree_resolve_dependencies_across_trees` —
    konkretny powód (status poprzednika / brak zależności) + następne działanie.
  - Kontynuacja po usunięciu przeszkody: powrót źródła do `ok` powoduje
    zniknięcie wiersza (widok liczony na żywo, `test_healthy_snapshot_has_empty_attention`).
- „Niedostępny forge, agent lub plik nie jest sukcesem ani sygnałem do
  uruchomienia zastępczej pracy na tym samym worktree."
  - `test_source_error_is_a_failure_row_next_to_healthy_sources`,
    `test_disabled_source_is_missing_data_and_never_ok` („does not confirm a
    free worktree"), `test_unknown_executor_state_is_missing_data_and_not_a_free_worktree`,
    `test_hitl_inbox_failure_is_missing_data_not_healthy`,
    `test_errored_task_tree_leaves_readiness_unverified` (błąd drzewa ≠ brak
    blokad), `test_worktrees_source_failure_is_error_not_empty_list` (istniejący,
    L7.2). Nieznany stan wykonawcy = traktuj worktree jako zajęty.
- „Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną
  rolę lub narzędzie."
  - `test_json_contract_carries_attention_sections` — pełny kształt JSON
    (`attention.blockers/failures/missing_data`, `next_action` w każdym wierszu);
    `test_table_renders_attention_first_with_detail_and_next_action` —
    sekcja attention wyrenderowana przed sekcjami źródeł.

## Weryfikacja

- `bin/ace-test ace-overseer all` → **356 testów, 1489 asercji, 0 failures**
  (baseline 337; +19 nowych testów w `status_attention_test.rb`).
- Smoke na żywo w worktree (`bin/ace-overseer status`): sekcja attention
  pokazała realne dane laba — `-- attention: 2 blockers, 28 failures,
  1 missing_data`, w tym BLOCKER „8c0.t.045.l: dependency not found",
  BLOCKER deklaratywny (8xa.t.ho4, „marked blocked; dependencies
  satisfied"), FAILURE `failed_assignment 8x0z1i` oraz probe_errory
  obcych worktree — wszystko obok zdrowych źródeł w jednym widoku.
- Zakres zmian wyłącznie `ace-overseer` + dokumenty; bez zmian cross-package.
- Commity: nie wykonywano (zgodnie z zasadami fali; komituje nadzorca).

## Decyzje

- Attention liczone z już zebranego snapshotu źródeł + istniejący
  `HitlInbox` — zero nowych fetcherów, zero nowego stanu (ADR-034).
- Drzewa przeszukiwane łącznie (projekt + `_overseer`) dla lookupu zależności.
- Task `blocked` ze spełnionymi zależnościami dostaje powód zastępczy
  „marked blocked in the <tree> tree" — blokada deklaratywna też jest widoczna.
- `draft`/`done`/terminalne nie są blokadami; skanowane tylko `pending`/`blocked`.
- Błąd źródła = FAILURE (awaria); wyłączone źródło = MISSING DATA (ślepy punkt);
  błąd drzewa tasków dodatkowo flaguje „readiness unverified".
- L7.3 (pi /continue-work) żyje w `ace-handbook-integration-pi` — bez zmian w
  tym pakiecie w tym tasku.

## Pytania otwarte

- Brak. Ewentualne przyszłe rozszerzenie: rozróżnienie „praca przerwana"
  (stalled) jako osobnej kategorii zamiast FAILURE — obecnie zgodnie z briefem
  w FAILURE.
