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
