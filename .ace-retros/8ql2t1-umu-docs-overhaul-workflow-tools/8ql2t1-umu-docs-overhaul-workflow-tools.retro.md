---
id: 8ql2t1
title: umu-docs-overhaul-workflow-tools
type: standard
tags: [docs, batch, workflow-tools]
created_at: "2026-03-22 01:52:17"
status: active
---

# Documentation Overhaul: Workflow Tool Packages

Batch of 4 tasks overhauling docs for ace-assign, ace-overseer, ace-tmux, ace-retro.

## What Went Well

- **Fork-based batch execution** worked well for parallelizing independent package work. Each package got its own isolated context for docs + release.
- **Three-cycle review process** (valid → fit → shine) caught real issues: missing gemspec `docs/**/*` globs, pipe examples violating project policy, messaging mismatches, dropped composition examples.
- **ace-git-commit scope grouping** produced clean reorganized commits (16 → 6) with accurate per-package messages.
- **Recovery from fork crashes** was handled systematically: commit partial work, inject recovery steps, re-fork. The pattern worked reliably across 2 crashed forks.

## What Could Be Improved

- **VHS demo recorder crashes** in the sandbox environment (segfault in `randomPort()`). Every package needed an ffmpeg fallback GIF. The tapes are authored but can't be re-recorded until VHS is fixed upstream.
- **Fork failures due to provider unavailability** — All three review subtrees (040, 070, 100) failed when `ace-assign fork-run` spawned an isolated agent that couldn't reach LLM providers needed by `ace-review`. Each time: fork started, `ace-review --pr 252` timed out inside the fork, fork exited non-zero with the step still Active. Per the workflow's provider-unavailability rules, review steps are LLM-tool steps (primary action is calling an LLM, not producing code), so the driver executed `ace-review` inline where providers were reachable — all three succeeded (3 models, 150-180s each). The tradeoff: fork isolation exists to keep review details out of the driver's context window. By executing inline, all 33 feedback items across 3 cycles landed in the driver context. For this docs-focused PR it was manageable; for a code-heavy PR with complex findings this could become a context pressure problem. A potential improvement: `fork-run` could retry with alternate provider config or surface the specific provider error for more targeted recovery.
- **Stray files from crashed forks** (e.g., `docs/demo/` at repo root) stalled subsequent forks. Forks should clean up partial output on crash.
- **ace-overseer and ace-tmux releases were missed** in their fork subtrees because the release step saw only task-spec files in the diff (docs were committed in an earlier step). The top-level release step (020) caught this, but the subtree release logic could be smarter about detecting changes from prior sibling steps.
- **Multiple patch releases** accumulated (v0.36.0 → v0.36.1 → v0.36.2 for ace-assign) due to review cycles. Commit reorganization folded these into one final state, but the changelog still shows intermediate versions.

## Key Learnings

- Documentation-only PRs still benefit from multi-model review — reviewers caught gemspec packaging gaps, anti-pattern examples, and content regressions that manual review would likely miss.
- The fork crash recovery protocol (commit → inject → re-fork) is reliable but adds ~5 minutes per crash. Worth investing in fork stability.

## Action Items

- **Continue**: Using three-cycle review for documentation PRs — it catches real issues
- **Continue**: Fork-based batch execution for independent package work
- **Start**: Investigating VHS crash in sandbox environments (segfault in tty.go)
- **Start**: Making fork subtree release steps aware of changes from prior sibling steps
- **Stop**: Generating multiple intermediate patch releases during review cycles — consider deferring release to after all review cycles complete
