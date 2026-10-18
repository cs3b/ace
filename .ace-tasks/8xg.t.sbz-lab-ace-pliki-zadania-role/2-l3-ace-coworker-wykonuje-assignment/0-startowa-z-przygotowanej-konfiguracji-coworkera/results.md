# Wyniki wykonania — 8xg.t.sbz.2.0 (Startować z przygotowanej konfiguracji coworkera)

Data: 2026-10-18. Zakres: nowy gem `ace-coworker` (faza A planu, kroki 01–03).

## Co powstało

- Gem `ace-coworker` v0.1.0: ATOM (atoms/molecules/organisms/models/cli), dry-cli
  (ADR-023), kaskada konfiguracji `.ace-defaults/coworker/config.yml` (ADR-022),
  binstub `bin/ace-coworker`.
- `ace-coworker start [--config] [--format table|json]`: ładuje i waliduje
  `.ace-local/coworker/config.yml` (rola, źródło instrukcji, prompt startowy,
  task, assignment, adres overseera, zasady błędów) z błędami per pole;
  rozwiązuje task w worktree (biblioteka ace-task), sprawdza zgodność
  assignment↔task (`.ace-local/assign/<id>/assignment.yaml` → `task_id`),
  odczytuje stan z `ace-assign status --format json`, rozwiązuje źródło
  instrukcji (plik względem worktree albo `wfi://`/`prompt://`/`tmpl://`
  przez `ace-nav resolve`) i drukuje executor brief przypinający
  `--assignment <id>`. Nic nie zapisuje; nie zgaduje zamiennego zlecenia.
- `ace-coworker status`: kwerenda gotowości — brak configu renderuje
  `not ready: .ace-local/coworker/config.yml not found` z exit 0.
- Kontrakt startowy udokumentowany w `ace-coworker/docs/usage.md`
  (jedno źródło dla plannera L4).

## Kryteria odbioru

- [x] Wykonawca startuje w przygotowanym worktree z właściwą rolą i dokładnie
  wskazanym assignmentem — test integracyjny
  `ace-coworker/test/commands/integration_test.rb`
  (`test_start_and_status_against_real_assignment`) na prawdziwym
  assignmentcie ace-assign + smoke run w /tmp (brief zawiera rolę, task,
  przypięty `--assignment`, overseera).
- [x] Brak instrukcji roli, taska albo assignmentu daje konkretny błąd —
  testy: `config_schema_test`, `config_loader_test`, `task_probe_test`,
  `assignment_metadata_test`, `instruction_resolver_test`,
  `start_orchestrator_test` (not-ready / not-in-worktree / mismatch /
  unknown-assignment / missing-instructions) oraz smoke run (start exit 1,
  status exit 0 z `not ready: …`).
- [x] Wynik zgodny z kontraktem i użyteczny przez następną rolę — format
  brief/status (table+json) udokumentowany w `docs/usage.md`; walidacja
  odwołań względem worktree (sciezki nie uciekają poza root).

## Weryfikacja

- `bin/ace-test ace-coworker all` — 54 testy, 0 błędów (w tym integracyjne
  z prawdziwym CLI ace-assign w projekcie tymczasowym).
- `bin/ace-test ace-assign` — 633 testy, 0 błędów (regresja).
- `bin/ace-test-suite` — patrz results grupy (8xg.t.sbz.2).
- `bin/ace-lint ace-coworker/README.md ace-coworker/docs/usage.md` — pass.
- Smoke: `/tmp/coworker-smoke.lHoQ` — start/status/drive/not-ready zgodne
  ze scenariuszem `ux/usage.md`.

Wysyłka HITL należy do `.2.2` (czeka na L2) — zgodnie z review gotowości.
