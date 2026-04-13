---
id: 8ql2wr
title: docs-overhaul-developer-tools
type: standard
tags: [docs, batch]
created_at: "2026-03-22 01:56:25"
status: active
---

# docs-overhaul-developer-tools

Retrospective on batch documentation overhaul for ace-search, ace-lint, ace-llm, and ace-docs (tasks 8q4.t.umv.0–3).

## What Went Well

- **Consistent template across packages**: All 4 packages followed the same README → landing page + getting-started + usage + handbook pattern. This made the work predictable and parallelizable.
- **Fork-based parallel execution**: The batch assignment structure with fork-run worked well for ace-lint, ace-llm, and ace-docs — each subtree completed autonomously with version bumps and changelogs.
- **3-cycle review caught real issues**: The valid review cycle found 5 real problems (broken frontmatter, Kramdown IAL syntax, malformed table, missing GIF, invalid preset reference). These would have shipped as broken documentation without review.
- **Driver recovery from fork failures**: When ace-search's fork crashed on VHS, the driver was able to commit partial work, advance past the failure, and re-fork for remaining steps. The recovery protocol worked.
- **Commit reorganization**: 18 granular commits cleaned up to 6 logical scope-grouped commits via `ace-git-commit` auto-grouping.

## What Could Be Improved

- **VHS environment compatibility**: VHS consistently crashes with nil pointer dereference in `tty.go:22` in this environment. 3 of 4 packages hit this. A pre-flight VHS health check or fallback renderer would avoid repeated failures.
- **Codex fork provider argument conflict**: The `--full-auto` vs `--dangerously-bypass-approvals-and-sandbox` conflict blocked fork-run for review cycles, forcing inline execution. This needs a provider config fix.
- **Fork agents producing malformed markdown**: The ace-docs fork agent generated Kramdown IAL syntax and collapsed YAML frontmatter. This suggests the Codex provider has different markdown conventions than expected. A lint gate before fork completion would catch this.
- **Feedback synthesis failures**: The fit review cycle's feedback synthesis failed twice (gemini:flash and claude:sonnet both returned non-JSON). Manual review report reading was required as fallback.
- **ace-search release gap**: Because the fork crashed and the release-minor step ran as no-op, ace-search's release had to be done manually at the top-level step. The fork recovery protocol should either re-run the release step or flag it for the driver.

## Key Learnings

- Documentation-only tasks don't need E2E or test verification, but the assignment still runs those steps. Consider adding skip conditions based on diff content type.
- Fork agents from different providers may produce markdown in their native style (Kramdown vs GFM). Post-fork lint validation should be mandatory.
- Review cycles converge quickly on docs PRs — the shine cycle found mostly duplicates of already-fixed issues. For docs-only PRs, 2 review cycles may be sufficient.

## Action Items

- **CONTINUE**: Using batch + fork pattern for multi-package docs work — the parallelism and isolation are valuable
- **START**: Adding a VHS pre-flight check to demo-recording steps (skip gracefully if VHS is broken)
- **START**: Running `ace-lint` on fork-produced markdown before marking work-on-task as done
- **STOP**: Running 3 full review cycles on docs-only PRs — 2 cycles (valid + fit) capture all substantive issues
