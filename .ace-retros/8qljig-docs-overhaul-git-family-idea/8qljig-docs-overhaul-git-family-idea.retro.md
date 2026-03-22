---
id: 8qljig
title: docs-overhaul-git-family-idea
type: standard
tags: [docs, batch, assignment]
created_at: "2026-03-22 13:00:30"
status: active
---

# Documentation Overhaul: ace-git family + ace-idea

Batch assignment `8ql46r` covering tasks 8q4.t.uno.0–3. Four packages documented in parallel via fork-run delegation to Codex.

## What Went Well

- **Fork-run delegation scaled well**: 4 independent doc tasks ran sequentially via fork-run with full context isolation. Each subtree (7 steps: onboard → task-load → plan → work → review → verify → release) completed autonomously.
- **Consistent output quality**: All 4 forks produced matching deliverables (README landing page, getting-started tutorial, usage ref, handbook catalog, VHS tape, demo GIF, gemspec update) without manual intervention.
- **Review cycles caught real issues**: Valid review found missing `docs/**/*` in gemspecs, duplicated CLI options, and Kramdown-only syntax. Shine review improved demo paths and queue terminology.
- **E2E tests green throughout**: 34/34 E2E tests passed across all modified packages despite being docs-only changes — confirmed no regressions.
- **Reorganize step worked cleanly**: 47 scattered commits collapsed to 9 logical scope-grouped commits via soft reset + ace-git-commit.

## What Could Be Improved

- **Review cycles reverted intentional config fixes (twice)**: The Codex yolo preset had `--full-auto` removed and the assign provider was switched to `codex:gpt@yolo` to fix a CLI argument conflict. Both the valid and fit review cycles reverted these changes, seeing them as "unrelated to the docs PR." This required manual re-fix each time and broke fork-run execution.
  - Root cause: review agents don't check `git log` to understand commit intent before reverting config diffs
  - Mitigation: added "PROTECTED FILES" guard instructions to step files — this worked for the shine review cycle
- **Pre-commit review skipped in all forks**: The fork provider (Codex) doesn't expose a native `/review` entrypoint, so all pre-commit-review steps were skipped. This meant the first real review was the post-PR valid cycle.
- **Release step created per-scope commits instead of single coordinated commit**: `ace-git-commit` auto-split release commits by scope, conflicting with the release workflow's single-commit requirement. Forks had to work around this manually.

## Key Learnings

- Fork-run config files (`.ace/assign/config.yml`, preset YAMLs) are both project settings AND runtime dependencies for the assignment itself. Reverting them mid-assignment breaks execution — they need special protection.
- Adding explicit "do not revert" instructions to step files is effective but shouldn't be necessary. The review workflow should check commit history before suggesting reversions of config changes.
- Documentation-only batches can safely skip test-suite verification and contract-update steps, saving significant time.

## Action Items

- **START**: Add git-log checks to the review workflow before flagging config diffs as "unrelated" — check if the change was an intentional early-branch fix
- **START**: Consider a "protected files" mechanism in ace-assign that automatically propagates to all fork step instructions
- **CONTINUE**: Using fork-run for independent task batches — the context isolation and autonomous execution worked well
- **STOP**: Relying on forks to handle config state correctly without explicit guidance — always add protection for assignment-critical config files

