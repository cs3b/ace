# Wynik 8xg.t.sbz.4.3 — Dostarczyć integratora zależnego od wyników pracy

Data: 2026-10-19. Worktree: `.ace-wt/t-sbz-wave-3` (branch `t-sbz-wave-3`).

## Co zaimplementowano

Czwarta rola coworkera — **integrator** — jako preset + workflow + deterministyczna
bramka pre-merge (czysty atom) z powierzchnią CLI, według wzorca .4.2
(atom + CLI; bez nowego store'a, bo decyzja integracji nie wymaga nowego artefaktu — patrz decyzje).

Integrator sprawdza przed merge cztery fakty: (a) zależności są zintegrowanymi
poprzednikami, (b) head kandydata == head objęty review (brak dryfu; zmiana
kandydata po review unieważnia review), (c) testy wykonane i zielone (CI doradcze),
(d) świeży werdykt niezależnego review = accept na DOKŁADNIE ten head kandydata.
Nieznany fakt blokuje z powodem "zweryfikuj, nie zgaduj" — niepewny wynik operacji
(merge/push) jest sprawdzany po stanie rzeczywistym, nie ponawiany w ciemno.
Blokada = wstrzymanie merge + eskalacja ace-hitl do overseera; merge który zmienia
kandydata (konflikty) wymaga odnowienia testów i review. Rola steruje git/ace-git;
kod nie wykonuje merge.

## Pliki

- `ace-coworker/handbook/workflow-instructions/coworker/integrator.wf.md` — nowy
  workflow roli (tożsamość, zbieranie faktów gate z ich właścicieli, ewaluacja,
  merge tylko ready, wstrzymanie blokad, raport wyniku odblokowujący zależnych,
  resume; rozwiązywalny przez `ace-bundle wfi://coworker/integrator`).
- `ace-coworker/.ace-defaults/coworker/roles/integrator.yml` — preset roli
  (name/description/instructions/start_prompt, reporting hitl, on_failure report).
- `ace-coworker/lib/ace/coworker/atoms/integration_gate.rb` — czysty atom
  `IntegrationGate.evaluate` → `{verdict: :ready|:blocked, reasons:, failed_checks:}`;
  nieznane/uszkodzone wejście = blokada z actionable powodem, nigdy wyjątek ani zgadywanie.
- `ace-coworker/lib/ace/coworker/cli/commands/gate.rb` + rejestracja w
  `cli.rb`/`coworker.rb` — `ace-coworker gate --candidate-head … --review-head …
  --review-verdict … --tests executed,passed --dep LEAF=integrated|missing`;
  `blocked` to legalny wynik (exit 0), tylko niepoprawne wejście kończy się błędem.
- `ace-coworker/test/atoms/integration_gate_test.rb` (11 testów),
  `ace-coworker/test/commands/gate_test.rb` (7 testów).
- `ace-coworker/README.md`, `ace-coworker/docs/usage.md` — rola w katalogu,
  sekcja `ace-coworker gate`, wiersz w tabeli exit codes.
- `ace-coworker/CHANGELOG.md` — wpisy [Unreleased]/Added (Keep a Changelog, EN).

## Testy

- Komenda: `bin/ace-test ace-coworker all` (z worktree, przez bin/ace-*).
- Wynik: **329 testów, 1342 asercje, 0 failures, 0 errors** (baseline 311; +18 nowych:
  11 atom + 7 command). Pełny raport: `.ace-local/test/reports/coworker/838aa168-…/`.
- Dodatkowo smoke: `bin/ace-coworker roles` listuje `integrator` (gem),
  `bin/ace-bundle wfi://coworker/integrator` renderuje workflow,
  `bin/ace-coworker gate …` drukuje `blocked: stale review…` dla dryfu,
  `bin/ace-lint` na zmienionych plikach: pass.

## Mapowanie kryteriów odbioru

1. *Gotowy i sprawdzony kandydat zostaje zintegrowany, raport wskazuje wynik* —
   scenariusz pozytywny: `IntegrationGateTest#test_ready_candidate_passes_the_gate`,
   `GateTest#test_ready_candidate_prints_ready_without_reasons`; instrukcja wf krok 4/6:
   merge tylko na `ready`, raport (`ace-coworker report`) podaje merged head/PR,
   odblokowane liście zależne, dowody gate (verdict, heady, liczby testów, werdykt review).
2. *Nieaktualne review / niespełniona zależność wstrzymują merge; niepewny wynik
   sprawdzany, nie ponawiany* — `test_stale_review_after_candidate_change_blocks`,
   `test_unsatisfied_dependency_blocks`, `test_tests_not_executed_or_not_passing_block`,
   `test_unknown_candidate_head_is_blocked_not_guessed`,
   `test_missing_review_head_blocks_as_unverifiable_evidence`,
   `test_missing_or_malformed_sections_block_instead_of_crashing` oraz odpowiedniki CLI;
   wf krok 2 (fakt nieustalony = zweryfikuj w stanie rzeczywistym) i krok 4
   (po merge weryfikuj stan; powtórny merge nie jest weryfikacją).
3. *Zgodność z kontraktem i używalność przez następną rolę/narzędzie* — preset pod
  `commission`/`roles` jak pozostałe role; workflow zgodny z kontraktem (merge gate =
   executed tests + niezależny werdykt, CI doradcze); raport zużywalny przez
   overseera/zależne taski; brak nowych właścicieli stanu (ADR-034).

## Decyzje

- **Bez store'a/CLI-persist**: brak nowego artefaktu — decyzja integracji jest
  pochodną faktów (git, raporty, review-rounds) w chwili wywołania, a trwały zapis
  trafia do istniejącego stanu raportu assignmentu (`ReportStateStore`,
  `<task>/coworker/<assignment>.md`). Dlatego NIE dodano wierszy w
  docs/lab-flow.md ani docs/tools.md (nie powstał nowy rodzaj artefaktu).
- CLI `gate` dodano (wzorzec `rounds record`), bo rola potrzebuje deterministycznej
  ewaluacji; jest stateless i nic nie zapisuje. `blocked` = exit 0 (legalny wynik
  bramki), błąd tylko dla niepoprawnego wejścia.
- Gate przyjmuje verdict "accept" (case-insensitive); każdą inną wartość
  (continue/escalate/brak) traktuje jako blokadę z powodem.

## Pytania otwarte

- Brak blokujących. Ewentualnie do decyzji Lead/overseera: czy raport integratora
  ma też aktualizować status liści zależnych w `.ace-tasks` (obecnie zgodnie z
  kontraktem robi to overseer we własnym procesie).

## Poprawki po review (runda 1)

Data: 2026-10-19. Zastosowano 9 zweryfikowanych uwag z
`.ace-local/review/sessions/review-8xiegq/review-report-review-default.md`.

1. (Medium) `gate.rb#dependency_states`: `--dep foo` bez `=` od teraz kończy
   się błędem `Ace::Support::Cli::Error` "invalid --dep 'foo' (expected
   name=integrated|missing)" zamiast cichego traktowania jako
   nie-zintegrowana. Test: `test_dep_without_state_fails_with_actionable_error`.
2. (Medium) Pełny SHA + normalizacja porównania: `integrator.wf.md` używa
   `git rev-parse HEAD` (nie `--short`) i stanowi, że heady zapisuje/porównuje
   się jako pełne lowercase SHA; dopełniające zdanie dodano w `reviewer.wf.md`
   (raportowany reviewowany head = pełny lowercase SHA). Atom porównuje
   `review_head.downcase != candidate_head.downcase` (różnica długości nadal
   blokuje). Testy: `test_head_comparison_tolerates_case_drift_but_not_length_mismatch`.
3. (Low) `gate.rb#tests_flags`: token spoza {executed, passed} → błąd
   "invalid --tests '<tok>' (expected: executed, passed)". Test:
   `test_unknown_tests_token_fails_with_actionable_error`.
4. (Low) Atom, gałąź nie-Hash: `failed_checks: [:input]` (nowy marker) zamiast
   `[:candidate]`; powód bez zmian. Zaktualizowano
   `test_non_hash_input_blocks_with_actionable_reason`.
5. (Low) `integrator.wf.md` (~29, ~102): usunięto cytowania labowego pliku
   "execution-order.md" (samowystarczalność ADR-001); reguły zostają inline,
   odwołanie przeformułowane na "per the lab's execution-order contract".
6. (Low) Zmiana nazwy testu: `test_symbol_verdict_and_accept_synonym` →
   `test_verdict_comparison_is_case_insensitive`.
7. (Low) Zduplikowane nazwy `--dep` odrzucane błędem "duplicate --dep
   '<name>'". Test: `test_duplicate_dep_name_fails_with_actionable_error`.
8. (Low) Dodano test ścieżki cichej `gate -q` (`test_quiet_suppresses_output`,
   lustrzany do pokrycia rounds).
9. (Low) `docs/usage.md`: zdanie, że puste/pominięte `--dep` oznacza "caller
   enumerated none" — bramka ufa enumeracji zależności wywołującego.

Aktualizacje dokumentacji towarzyszących: `docs/usage.md` (kontrakt błędów
gate: nieprawidłowy/duplikat `--dep`, nieznany token `--tests`; pełne
lowercase SHA), `CHANGELOG.md` [Unreleased] (kontrakt błędów + normalizacja
SHA). Nie zmieniono glyph kontraktu wyjścia atoms poza markerem `:input`.

Weryfikacja: `bin/ace-test ace-coworker all` → **334 testy, 1355 asercji,
0 failures, 0 errors** (poprzednio 329; +5 nowych testów). Raport:
`.ace-local/test/reports/coworker/bc689275-ef69-47a6-92af-0239bd0bddf9/`.
