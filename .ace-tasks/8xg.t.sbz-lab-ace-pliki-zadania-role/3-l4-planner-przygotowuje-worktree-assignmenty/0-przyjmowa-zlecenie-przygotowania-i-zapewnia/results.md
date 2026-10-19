# Wynik wykonania — 8xg.t.sbz.3.0 (L4.1)

Data: 2026-10-18. Branch: `t-sbz-wave-2` (worktree `.ace-wt/t-sbz-wave-2`), zakres `3a3d00e04..HEAD`.

## Dostarczenie

`ace-coworker prepare --task REF --roles a,b [--to] [--config] [--dry-run] [--format table|json]` (ace-coworker 0.3.2 → **0.4.0**):

- deterministyczna procedura: switch → weryfikacja skojarzenia → create → stale-recovery (prune + reattach gałęzi zachowujący pracę) → probe aktywnego wykonawcy → reuse (zero zapisów) lub konflikt;
- konflikt `active_executor` / `mismatched_worktree` → pytanie HITL do overseera (`--type question --kind decision`), nigdy nadpisanie pracy; niedoręczne zdarzenie zachowuje id do ponownego `send`;
- nowa zależność runtime `ace-git-worktree ~> 0.27` (użycie biblioteczne, jak ace-overseer).

Pliki: `models/preparation.rb`, `atoms/{prepare_decision,active_executor_rule}.rb`, `molecules/{worktree_provision_probe,worktree_executor_probe}.rb`, `organisms/prepare_orchestrator.rb`, `cli/commands/prepare.rb` + 6 plików testów (w tym integracyjny na prawdziwym git + binstubach).

## Kryteria odbioru → dowody

1. **Idempotentne re-przygotowanie** — integracyjny `prepare_integration_test.rb`: ponowne `prepare` → `reused`, exit 0, `git status` i bajty plików niezmienione (zero zapisów).
2. **Konflikt zamiast nadpisania** — testy integracyjne: aktywny wykonawca (commissioned running) i zajęta lokalizacja → `mismatched_worktree`/`active_executor`, exit 1, zdarzenie HITL utworzone, praca zachowana (snapshot MD5).
3. **Zgodność z kontraktem / użyteczność** — JSON/table zgodny z `docs/usage.md`; `active_executor` niesie dowód (assignment/state/source) dla L4.2; ADR-034 bez nowych właścicieli stanu.

## Weryfikacja

- `bin/ace-test ace-coworker all` → **210 testów, 872 asercji, 0 failed** (atoms 48, molecules 75, organisms 51, models 1, commands 35).
- `bin/ace-test-suite` → 52 pakiety, **11 973 testów, 0 failed**, 41 skipped (przed poprawkami M1/M2; po nich pakiet coworker 210/0 — suite monorepo powtórzy się w bramce PR).
- `bin/ace-lint` na zmienionym markdown: bez nowych ostrzeżeń.

## Review

- Runda 1 (`.ace-local/review/sessions/review-8xhvfa`): 0 Critical/High; 2×Medium (M1 martwa ścieżka stale + dry-run; M2 ukończony commission maskuje in-flight), 4×Low — wszystkie naprawione (commity `0d70551d8`, `5b0a4ca61`, `1ab205104`, `2f5577607`); feedback `8xhvpfxc`–`8xhvpfxh` resolved `fixed`.
- Runda 2 (`.ace-local/review/sessions/review-8xhw02`): werdykt **Approve** (0 Critical/High); 4 niskie action-items naprawione w `9a932e1ee`.
- Naprawa M1 odkryła dodatkowy bug: real-run recovery nigdy nie działał („branch already exists" po prune) — `recover_stale` reattachu ocalałą gałąź z pracą; pokryte testem integracyjnym.

## Commity (zakres 3.0)

`c3393edd7`, `0da234e27`, `fe287371e`, `e82a6c482`, `4fb623881`, `05ef0da7d`, `81d124f12`, `15d19ba15`, `0d70551d8`, `5b0a4ca61`, `1ab205104`, `2f5577607`, `9a932e1ee`.
