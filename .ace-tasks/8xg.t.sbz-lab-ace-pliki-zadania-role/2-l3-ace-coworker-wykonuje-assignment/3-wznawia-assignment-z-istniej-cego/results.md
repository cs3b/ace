# Wynik realizacji — 8xg.t.sbz.2.3 (L3.4: wznawiać assignment z istniejącego worktree)

Data: 2026-10-18. Ten sam worktree i ten sam PR #383.

## Co powstało

- **`ace-coworker resume`** (coworker 0.2.0 → 0.3.0):
  - **Ten sam task, assignment i worktree** — łańcuch walidacji identyczny z
    `start` (te same komunikaty błędów), zero tworzenia nowych
    tasków/worktree, zero resetowania lokalnych zmian. Resume samo nie
    prowadzi kroków assignmentu (wykonawca prowadzi przez ace-assign).
  - **`:continue`** (assignment niedokończony): zachowane kroki done,
    pozostała praca, krok w locie (active, inaczej failed) z zapisaną
    przyczyną (pole `error:` z pliku stanu kroku) i raportem + wytyczną
    verify-before-repeat; lista lokalnych zmian (preserved, never reset);
    **effect caution** dla kroków merge/publish/deploy/release/push:
    sprawdzić faktyczny stan istniejącym narzędziem (ace-git status, PR
    evidence) albo zgłosić blokadę — nigdy ślepe ponowienie.
  - **`:report`** (assignment kompletny, dostawa raportu brakująca):
    delegacja do istniejącego `report` — resend **tego samego ID zdarzenia
    HITL** (ponawianie dostawy ≠ ponawianie zadania; test integracyjny
    asercją „drugi resume = wciąż 1 zdarzenie").
  - **`:complete`** — informacyjnie, exit 0. `--dry-run` — plan bez zapisów.
  - Zero journala/checkpoint-store: stan worktree (GitStateProbe, tylko
    read-only `status`/`log`), pliki kroków ace-assign i stan raportu TO
    checkpoint (ADR-034).

## Kryteria odbioru

- [x] Restart w połowie zlecenia zachowuje ukończone kroki i lokalne
  zmiany oraz wraca do pracy pozostałej do wykonania — integracyjny
  `test_mid_step_interruption_preserves_work_and_returns_to_remaining`
  (realne ace-assign + git: krok 010 zachowany, 020/030 w remaining,
  local-notes.md obecny przed i po, liczba tasków/assignmentów bez zmian,
  brak .ace-wt).
- [x] Jeżeli nie wiadomo, czy merge/publikacja zaszły, sprawdzić ich stan
  lub zgłosić blokadę zamiast ślepo wykonywać; nie tworzyć nowego
  taska/worktree — `test_uncertain_external_effect_gets_check_or_block_guidance`
  (effect caution + wskazanie ace-git status/PR evidence; resume nie
  wykonało żadnego efektu); całość read-only na ścieżce continue.
- [x] Wynik zgodny z kontraktem i użyteczny — brief resume (identity,
  preserved/remaining, in-flight z przyczyną, local changes, caution,
  redelivery) czytelny dla następnej roli; `:report` z tego samego ID
  zdarzenia; `test_complete_but_undelivered_resumes_report_with_same_event_id`
  + `test_complete_and_delivered_is_informational`.

## Weryfikacja

- `bin/ace-test ace-coworker all` — 125 testów, 0 błędów (nowe: planner 7,
  molekuły 7, orchestrator 6, integracyjne 6 z realnymi binstubami).
- Lint: usage/README/CHANGELOG — passed.
