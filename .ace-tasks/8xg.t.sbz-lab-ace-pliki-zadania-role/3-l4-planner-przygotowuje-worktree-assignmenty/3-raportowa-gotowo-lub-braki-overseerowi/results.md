# Wyniki: 8xg.t.sbz.3.3 — Raportować gotowość lub braki overseerowi (L4.4)

Status: zaimplementowane i zweryfikowane. `bin/ace-test ace-coworker all`:
**377 testów, 0 failures** (baseline 369; +8 testów netto: nowe testy
readiness/gap, przepisane testy braku adresu i błędów ról).

## Zakres

Pakiet `ace-coworker` (organizm + model + molekuła + CLI + testy + docs +
CHANGELOG). Żaden inny pakiet nie wymaga zmiany — ace-hitl pozostaje
transportem i właścicielem zdarzeń (kontrakt: raport = bez odpowiedzi;
pytanie/eskalacja = wymaga odpowiedzi; zdarzenia w plikach agenta).

## Zmienione pliki

- `ace-coworker/lib/ace/coworker/organisms/prepare_orchestrator.rb` —
  raport gotowości po sukcesie; braki `role_sequence` i `missing_overseer`
  jako konflikty (eskalacja pytaniem/decyzją), zamiast gołych błędów.
- `ace-coworker/lib/ace/coworker/models/preparation.rb` — nowe pole
  `report` ({"kind" => "readiness", "event", "delivered"} lub "error"),
  widoczne w `to_h`/JSON.
- `ace-coworker/lib/ace/coworker/molecules/hitl_reporter.rb` — nowa metoda
  `create_report` (typ `report`, wymusza `--result success|error` zgodnie
  z CLI ace-hitl); wysyłka przez istniejące `send_report`.
- `ace-coworker/lib/ace/coworker/cli/commands/prepare.rb` — render pola
  `report` (delivered / retry `ace-hitl send <id>` / powód błędu).
- `ace-coworker/test/organisms/prepare_orchestrator_test.rb` — FakeHitl z
  `create_report`; testy: sukces → raport gotowości (treść: worktree,
  assignmenty, start configi, pierwszy krok); `missing_overseer` → gap
  (nie gotowe, bez raportu gotowości, notka o braku adresu);
  `role_sequence` → gap z eskalacją pytaniem (i wariant bez adresata);
  niedoręczenie / nieudane create / brak binarki ace-hitl → zapisane w
  `report`, nie cofają przygotowania; dry-run → brak raportu.
- `ace-coworker/test/commands/prepare_test.rb` — render raportu (3
  warianty) + `report` w JSON.
- `ace-coworker/test/commands/prepare_integration_test.rb` — nowy test
  E2E: sukces → zdarzenie HITL `type: report`, `result: success`, adresat
  z konfiguracji, treść z kompletem do pierwszego kroku; zaktualizowane
  testy `missing_overseer` i `role_sequence` (eskalacja pytaniem);
  liczniki zdarzeń w fixture'ach.
- `ace-coworker/docs/usage.md` — usunięta notka „readiness report (L4.4)
  remains a later leaf"; sekcja Readiness/gap reporting; zaktualizowane
  opisy braku adresu i błędów ról; `report` w JSON wyniku; tabela exit
  codes.
- `ace-coworker/CHANGELOG.md` — wpis [Unreleased] (EN) + korelacja wpisu
  L4.3.

## Mapowanie kryteriów odbioru (ze specyfikacji)

1. **Overseer otrzymuje komplet do uruchomienia pierwszego kroku; nie musi
   sam komponować szczegółowego ace-assign.** — raport gotowości (`type:
   report`, bez oczekiwania odpowiedzi) zawiera worktree (path/branch/
   disposition), każdą nogę sekwencji (`sequence N/M <role>:
   <assignment>`), każdy start config i dokładny pierwszy krok
   (`ace-coworker start --config .ace-local/coworker/prepare/<first>.yml`
   w worktree). Testy: unit `test_happy_create_returns_preparation`,
   integracyjny `test_prepare_sends_readiness_report_to_the_overseer`.
2. **Niepełna konfiguracja lub brak worktree nie są raportowane jako
   gotowe zlecenie i nie uruchamiają nieprzygotowanego coworkera.** —
   `missing_overseer` i `role_sequence` to konflikty: exit 1, brak pola
   `worktree` w wyniku, brak `report`, żadne start configi nie są
   zapisane; eskalacja pytaniem (`type: question`, `kind: decision`) z
   listą „prepared: … / decision needed: …". Brak worktree to istniejące
   konflikty `mismatched_worktree`/`active_executor` (bez zmian).
   Testy: unit `test_missing_start_config_overseer_is_a_gap_not_ready`,
   `test_sequence_composition_error_*`; integracyjne
   `test_prepare_without_overseer_writes_no_start_configs`,
   `test_missing_role_process_reports_and_writes_no_assignments`.
3. **Wynik zgodny z kontraktem i użyteczny przez następną rolę/narzędzie.**
   — raport idzie przez ace-hitl (właściciel zdarzeń), start configi są
   konsumowane przez `ace-coworker start --config` (test round-trip z
   L4.3 nadal przechodzi); brak nowego właściciela stanu (ADR-034).

Scenariusz dry-run (ux/usage.md): zero efektów łącznie z ace-hitl — brak
raportu gotowości i brak eskalacji (testy unit i integracyjne).

## Decyzje

- Raport gotowości wysyłany przy KAŻDYM udanym prepare (także reuse):
  raport dotyczy komisji (odpowiedź overseerowi), nie zapisu plików;
  idempotentność zapisów pozostaje. Alternatywa (raport tylko przy
  created/updated) odrzucona jako spekulatywna reguła.
- Niedoręczenie raportu gotowości nie cofa przygotowania i nie zmienia
  exit code (0): wynik pracy jest gotowy; `report.delivered == false`
  plus hint `ace-hitl send <id>` umożliwia retry — ponowienie dostarczenia
  nie jest ponowieniem wykonania (kontrakt). Eskalacja konfliktu
  pozostaje na exit 1 (bez zmian).
- Zastąpiono goły błąd `cannot prepare start configs: no overseer
  address` strukturalnym gapem `missing_overseer` (spójny z resztą
  konfliktów; no backward compat, ADR-024).
- Błędy operacyjne StartConfigWritera nadal-raised (rzadkie awarie
  commission primitive, po wstępnej walidacji nóg) — poza listą braków z
  taska; wyszczególnione tutaj jako świadoma granica.
- docs/lab-flow.md bez zmian: raporty przechodzą przez istniejący stan
  ace-hitl (`.ace-local/hitl/`), nowy rodzaj artefaktu nie powstaje.

## Otwarte pytania

- Brak blokujących. Ewentualnie (poza zakresem): czy rerun prepare z
  identycznym stanem powinien deduplikować raport gotowości (dziś każdy
  rerun = nowy raport; overseer interpretuje zgodnie z kontraktem).

## Poprawki po review (runda 1)

Session `review-8xigto`, werdykt Approve, 6 findingów (1 Medium, 5 Low) — wszystkie applied:
1. (+test) dry-run + reuse + brak overseera = GAP bez eskalacji, bez zapisów i zdarzeń HITL.
2. Usunięty zdublowany note lenient-config w detail `missing_overseer` (note dodaje raz conflict_result).
3. Usunięty osierocony komentarz po `leg_config_overseer`.
4. `@return [String, Failure]` w HitlReporter (create/create_report/create_conflict).
5. Pełny cytat stderr gapu w docs/usage.md (z "; the commission is NOT ready…" i dopiskiem o liniach detail).
6. Asercja `payload["report"]` (kind/event/delivered) w teście JSON contract.
Retest: `bin/ace-test ace-coworker all` → 378/1727/0.
